"""Read-only comparison of a saved Data Modeler 18.2 design and an Oracle snapshot."""
from pathlib import Path
import argparse
import re
import sys
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument("--require-logical", action="store_true")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
design_file = root / "models/university.dmd"
model_root = design_file.with_suffix("")
snapshot = root / "results/schema-snapshot.txt"
report_path = root / "results/model-validation.txt"
lines = []
failed = []

def check(condition, label):
    lines.append(("PASS: " if condition else "FAIL: ") + label)
    if not condition:
        failed.append(label)

def upper(value):
    return (value or "").upper()

def norm_sql(value):
    return re.sub(r"\s+", "", value or "").upper()

tables = {}
columns = {}
keys = {}
foreign_keys = {}
checks = {}
for line in snapshot.read_text(encoding="utf-8-sig").splitlines():
    p = line.strip().split("|")
    if p[0] == "TABLE":
        tables[p[1]] = True
    elif p[0] == "COLUMN" and p[1] in tables:
        columns[(p[1], p[2])] = p[3:]
    elif p[0] == "KEY":
        keys[(p[1], p[2])] = (p[3], p[4].split(","))
    elif p[0] == "FK":
        foreign_keys[(p[1], p[2])] = (p[3].split(","), p[4], p[5].split(","))
    elif p[0] == "CHECK" and p[2].endswith("_CK"):
        checks[(p[1], p[2])] = "|".join(p[3:])

check(design_file.is_file(), "Native .dmd file exists")
ET.parse(design_file)
domains = {}
for path in (model_root / "domains").glob("*.xml"):
    for domain in ET.parse(path).getroot().findall("./domains/Domain"):
        domains[domain.get("id")] = domain

model_tables = {}
table_ids = {}
column_ids = {}
index_ids = {}
model_columns = {}
model_keys = {}
model_checks = {}
non_fk_indexes = 0
for path in model_root.glob("rel/*/table/*/*.xml"):
    table = ET.parse(path).getroot()
    name = upper(table.get("name"))
    model_tables[name] = table
    table_ids[table.get("id")] = name
    for column in table.findall("./columns/Column"):
        column_name = upper(column.get("name"))
        column_ids[column.get("id")] = (name, column_name)
        model_columns[(name, column_name)] = column
    for index in table.findall("./indexes/ind_PK_UK"):
        refs = [upper(next(c.get("name") for c in table.findall("./columns/Column")
                           if c.get("id") == usage.get("columnID")))
                for usage in index.findall("./indexColumnUsage/colUsage")]
        index_ids[index.get("id")] = refs
        state = index.findtext("indexState")
        if state != "Foreign Key":
            non_fk_indexes += 1
        if state in ("Primary Constraint", "Unique Constraint"):
            model_keys[(name, upper(index.get("name")))] = (
                "P" if state == "Primary Constraint" else "U", refs)
    for constraint in table.findall("./tableCheckConstraints/tableCheckConstraint"):
        model_checks[(name, upper(constraint.get("name")))] = constraint.findtext("rule", "")

check(set(model_tables) == set(tables), "All 10 table names match Oracle")
check(set(model_columns) == set(columns), "All 35 columns match Oracle")
logical_types = {"LOGDT019": "NUMBER", "LOGDT024": "VARCHAR2", "LOGDT007": "DATE"}
for key, expected in columns.items():
    column = model_columns.get(key)
    if column is None:
        continue
    domain = domains.get(column.findtext("domain"))
    logical_type = column.findtext("logicalDatatype")
    if domain is not None:
        logical_type = domain.findtext("logicalDatatype", logical_type)
    actual_type = logical_types.get(logical_type, logical_type)
    check(actual_type == expected[0], ".".join(key) + " datatype")
    actual_nulls = "Y" if column.findtext("nullsAllowed", "false") == "true" else "N"
    check(actual_nulls == expected[3], ".".join(key) + " nullability")
    if expected[0] == "VARCHAR2":
        size = domain.findtext("dataTypeSize", "") if domain is not None else column.findtext("dataTypeSize", "")
        check(size.lower().strip() == expected[1] + " char", ".".join(key) + " character length/CHAR semantics")
    elif expected[0] == "NUMBER" and domain is not None:
        precision = domain.findtext("dataTypePrecision", "0")
        scale = domain.findtext("dataTypeScale", "0")
        check(precision in ("", "0") and scale in ("", "0"), ".".join(key) + " unscaled NUMBER")

check(model_keys == keys, "All 10 PK and 5 UNIQUE keys match, including column order")
check(set(model_checks) == set(checks), "All 23 named CHECK constraints present")
for key, expected in checks.items():
    check(norm_sql(model_checks.get(key)) == norm_sql(expected), ".".join(key) + " CHECK expression")
check(non_fk_indexes == 22, "22 PK/UNIQUE/explicit indexes; FK diagram placeholders excluded")

model_fk = {}
for path in model_root.glob("rel/*/foreignkey/*/*.xml"):
    fk = ET.parse(path).getroot()
    child = table_ids[fk.get("containerWithKeyObject")]
    parent = table_ids[fk.findtext("referredTableID")]
    key = (child, upper(fk.get("name")))
    child_columns = index_ids[fk.get("localFKIndex")]
    parent_columns = index_ids[fk.findtext("referredKeyID")]
    model_fk[key] = (child_columns, parent, parent_columns)
    check(fk.findtext("mandatory") == "true", key[1] + " mandatory child reference")
check(model_fk == foreign_keys, "All 10 FK match child/parent tables and column mappings")

entities = list(model_root.glob("logical/entity/*/*.xml"))
relations = list(model_root.glob("logical/relation/*/*.xml"))
def logical_table_name(entity):
    name = upper(entity.get("name")).replace(" ", "_")
    aliases = {"STUDENT":"STUDENTS", "TEACHER":"TEACHERS", "DISCIPLINE":"DISCIPLINES",
               "GRADE":"GRADES", "SPECIALTY":"SPECIALTIES", "ACADEMIC_TITLE":"ACADEMIC_TITLES",
               "STUDY_YEAR":"STUDY_YEARS", "SEMESTER":"SEMESTERS", "DISCIPLINE_TEACHER":"DISCIPLINE_TEACHERS"}
    return aliases.get(name, name)
entity_roots = [ET.parse(p).getroot() for p in entities]
entity_names = {logical_table_name(e) for e in entity_roots}
lines.append("Logical model: " + str(len(entities)) + " entities, " + str(len(relations)) + " relations")
if args.require_logical or entities:
    check(entity_names == set(tables), "Logical entities match all 10 tables")
    check(len(relations) == 10, "Logical model has 10 relations")
    entity_ids = {e.get("id"): logical_table_name(e) for e in entity_roots}
    logical_columns = {(logical_table_name(e), upper(a.get("name")).replace(" ", "_"))
                       for e in entity_roots for a in e.findall("./attributes/Attribute")}
    check(logical_columns == set(columns), "All 35 logical attributes match columns")
    attributes = {(logical_table_name(e), upper(a.get("name")).replace(" ", "_")): a
                  for e in entity_roots for a in e.findall("./attributes/Attribute")}
    for key, expected in columns.items():
        a = attributes.get(key)
        if a is None: continue
        domain = domains.get(a.findtext("domain"))
        dtype = domain.findtext("logicalDatatype") if domain is not None else a.findtext("logicalDatatype")
        check(logical_types.get(dtype, dtype) == expected[0], ".".join(key) + " logical datatype")
        check(("Y" if a.findtext("nullsAllowed", "false") == "true" else "N") == expected[3],
              ".".join(key) + " logical optionality")
        if expected[0] == "VARCHAR2":
            size = domain.findtext("dataTypeSize", "") if domain is not None else a.findtext("dataTypeSize", "")
            check(size.lower().strip() == expected[1] + " char", ".".join(key) + " logical character length")
        elif expected[0] == "NUMBER" and domain is not None:
            check(domain.findtext("dataTypePrecision", "0") in ("", "0") and
                  domain.findtext("dataTypeScale", "0") in ("", "0"), ".".join(key) + " logical unscaled number")
    for e in entity_roots:
        name = logical_table_name(e)
        attr_names = {a.get("id"): upper(a.get("name")).replace(" ", "_")
                      for a in e.findall("./attributes/Attribute")}
        actual_uids = {("P" if uid.findtext("pk") == "true" else "U",
                        tuple(attr_names[ref.text] for ref in uid.findall("./usedAttributes/attributeRef")))
                       for uid in e.findall("./identifiers/identifier")}
        expected_uids = {(kind, tuple(refs)) for (table, _), (kind, refs) in keys.items() if table == name}
        check(actual_uids == expected_uids, name + " primary/secondary UID mapping")

    for path in relations:
        relation = ET.parse(path).getroot()
        child = entity_ids[relation.findtext("targetEntity")]
        parent = entity_ids[relation.findtext("sourceEntity")]
        expected = foreign_keys.get((child, upper(relation.get("name"))))
        check(expected is not None and expected[1] == parent, upper(relation.get("name")) + " logical endpoints")
        check(relation.findtext("optionalTarget") == "false", upper(relation.get("name")) + " child requires one parent")
        check(expected is not None and all(
            attributes[(child, c)].findtext("referedAttribute") == attributes[(parent, pc)].get("id")
            for c, pc in zip(expected[0], expected[2])),
            upper(relation.get("name")) + " logical attribute reference mapping")

        if relation.get("name").lower() in ("grades_student_fk", "dt_teacher_fk"):
            check(relation.findtext("optionalSource") == "false", upper(relation.get("name")) + " parent participation required")
            check("2..N" in relation.findtext("nameOnSource", ""), upper(relation.get("name")) + " explicit minimum-two label")
            check("TWO distinct disciplines" in relation.findtext("commentInRDBMS", ""), upper(relation.get("name")) + " explicit minimum-two comment")
    check(all(e.findtext("normalForm") == "Third" and e.findtext("adequatelyNormalized") == "YES"
              for e in entity_roots), "All logical entities record reviewed third normal form")
    check(all(t.findtext("normalForm") == "Third" and t.findtext("adequatelyNormalized") == "YES"
              for t in model_tables.values()), "All relational tables record reviewed third normal form")
    for pattern,obj_type,expected in [('rel/*/Objects.local','Table',set(table_ids)),('logical/Objects.local','Entity',set(entity_ids))]:
        registry = ET.parse(next(model_root.glob(pattern))).getroot()
        check({n.get('objectID') for n in registry if n.get('objectType')==obj_type} == expected,
              obj_type + ' registry contains exactly the actual native objects')
    fk_registry=ET.parse(next(model_root.glob('rel/*/Objects.local'))).getroot()
    registry_fks={n.get('objectID'):n for n in fk_registry if n.get('objectType')=='FKIndexAssociation'}
    for p in model_root.glob('rel/*/foreignkey/*/*.xml'):
        f=ET.parse(p).getroot();n=registry_fks.get(f.get('id'))
        check(n is not None and n.get('containerID')==f.get('containerWithKeyObject') and
              n.get('refContainerID')==f.findtext('referredTableID'),f.get('name')+' native FK registry endpoints')
    physical_tables={p.stem:ET.parse(p).getroot() for p in model_root.glob('rel/*/phys/*/Table/seg_0/*.xml')}
    check(set(physical_tables)==set(table_ids),'Oracle physical proxies match all ten relational tables')
    for tid,name in table_ids.items():
        actual={c.get('name').upper() for c in physical_tables[tid].findall('./columnProxies/ColumnProxy')}
        expected={c for table,c in columns if table==name}
        check(actual==expected,name+' Oracle physical column proxies')
    mapping=ET.parse(next(model_root.glob('mapping/ExtendedMap_RM*.xml'))).getroot()
    pairs={(n.get('lID'),n.get('rID')) for n in mapping.findall('./mappings/CM')}
    for e in entity_roots:
        check((e.get('id'),e.findtext('generatorID')) in pairs,logical_table_name(e)+' engineering map')
    discipline_relation=next(ET.parse(p).getroot() for p in relations if ET.parse(p).getroot().get('name').upper()=='DT_DISCIPLINE_FK')
    check(discipline_relation.findtext('optionalSource')=='false' and '1..N' in discipline_relation.findtext('nameOnSource',''),
          'Every discipline requires one or more teaching assignments')
else:
    lines.append("PENDING: Reverse engineering into the logical model")
lines.append("This check validates native structure only. Native GUI appearance and separately rendered diagrams need visual review.")
lines.append("Native structural checks passed: " + str(sum(line.startswith("PASS:") for line in lines)))
lines.append("MODEL_VALIDATION_" + ("FAILED" if failed else "PASSED"))
report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
sys.exit(1 if failed else 0)

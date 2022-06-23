##
# to read an excel spreadsheet and produce an intermine model
# (additions.xml file)
# using the /Users/sergio/NHS/ccc/ccc_data_slim.csv file
#
# header: 
# TABLE_NAME,COLUMN_NAME,DATA_TYPE
#

import pandas as pd
import xml.etree.ElementTree as ET

#Define function to build attribute nodes
def create_attribute(row, parent_node):
    """Add attributes based on row values of specific columns

    :param row: dataframe row
    :param parent_node: xml.subelement object
    """
    src_field = row["COLUMN_NAME"]
    src_datatype = row["DATA_TYPE"]
    attribute = ET.SubElement(parent_node, "attribute")
    attribute.set("name", src_field)
    attribute.set("type", src_datatype.split(' ')[0])

#Read in your DataFrame
df = pd.read_csv("/Users/sergio/NHS/ccc/ccc_data_slim.csv", sep=",")

#get classes by getting unique vals on correct column
class_names = df["TABLE_NAME"].unique().tolist()

field_names = df["COLUMN_NAME"].unique().tolist()


dfsmall = df[["TABLE_NAME", "COLUMN_NAME"]]

#print (dfsmall)


#loop through fields
for field_name in field_names:
  df_filt = dfsmall[dfsmall["TABLE_NAME"] != field_name]
#print (df_filt)


#loop through fields
for class_name in class_names:
  df_filt = dfsmall["COLUMN_NAME"].str.startswith(class_name)

#print (df_filt)


#loop through fields
# for field_name in field_names:
#   for class_name in class_names:
#     df_filt = dfsmall[dfsmall[field_name.startswith(class_name)]]
#     print (df_filt)


#print (df[["src_table","src_field"]])



# begin building xmltree
xml_data = ET.Element("data")

#loop through classes
for class_name in class_names:
    df_filt = df[df["TABLE_NAME"] == class_name]
    patient_class = ET.SubElement(xml_data, "class")
    patient_class.set("name", class_name)
    df_filt.apply(create_attribute, parent_node=patient_class,axis=1)

# save to file
#ET.ElementTree(xml_data).write("imrio.xml")
ET.ElementTree(xml_data).write("ccc2test.xml")
#ET.indent(xml_data)

# to go to stdout and the format, i.e.:
# python ccc2im.py | xmllint --format - > myputput.xml

ET.dump(xml_data)

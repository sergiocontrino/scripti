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

DATASET = "synthetic RiO"
DATASOURCE = "RiO"


#Define function to build attribute nodes
def create_attribute(row, parent_node):
    """Add attributes based on row values of specific columns

    :param row: dataframe row
    :param parent_node: xml.subelement object
    """
    src_field = row["COLUMN_NAME"]
    src_datatype = row["DATA_TYPE"]
    attribute = ET.SubElement(parent_node, "property")
    attribute.set("name", "delimited.colums")
    attribute.set("value", class_name + "." + src_field)
        
    


def create_cols_attribute(cols, parent_node):
    """Add attributes based on row values of specific columns

    :param row: dataframe row
    :param parent_node: xml.subelement object
    """
    src_field = row["COLUMN_NAME"]
    src_datatype = row["DATA_TYPE"]
    attribute = ET.SubElement(parent_node, "property")
    attribute.set("name", "delimited.colums")
    attribute.set("value", cols)


#Read in your DataFrame
#df = pd.read_csv("/Users/sergio/NHS/ccc/ccc_data_slim.csv", sep=",")
df = pd.read_csv("/Users/sergio/Desktop/ccs_redux.csv", sep=",")

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


#print (df[["src_table","src_field"]])

DATASOURCE = "synthetic Rio"
DATASET = "Rio??"
DATADIR = "/Users/sergio/data/camchild/RIO" 

# these should be fixed
DATASOURCENAME = "delimited.dataSourceName"
DATASETNAME = "delimited.dataSetTitle"
HEADERNAME = "delimited.hasHeader"
HEADER = "true"
SEPARATORNAME = "delimited.separator"
SEPARATOR = "comma"
DATADIRNAME = "src.data.dir"
INCLUDESNAME = "delimited.includes"


# begin building xmltree
xml_data = ET.Element("sources")

#loop through classes
for class_name in class_names:
    df_filt = df[df["TABLE_NAME"] == class_name]
    patient_class = ET.SubElement(xml_data, "source")
    patient_class.set("name", class_name)
    patient_class.set("type", "delimited")
    
    attribute = ET.SubElement(patient_class, "property")
    attribute.set("name", DATASOURCENAME)
    attribute.set("value",DATASOURCE)
    attribute = ET.SubElement(patient_class, "property")
    attribute.set("name", DATASETNAME)
    attribute.set("value", DATASET)
    attribute = ET.SubElement(patient_class, "property")
    attribute.set("name", HEADERNAME)
    attribute.set("value", HEADER)

    attribute = ET.SubElement(patient_class, "property")
    attribute.set("name", SEPARATORNAME)
    attribute.set("value", SEPARATOR)
    
    attribute = ET.SubElement(patient_class, "property")
    attribute.set("name", DATADIRNAME)
    attribute.set("location", DATADIR)
    
    attribute = ET.SubElement(patient_class, "property")
    attribute.set("name", INCLUDESNAME)
    attribute.set("value", class_name + ".csv")

    df_filt.apply(create_attribute, parent_node=patient_class,axis=1)

# save to file
#ET.ElementTree(xml_data).write("imrio.xml")
ET.ElementTree(xml_data).write("pro-test.xml")

# to go to stdout and the format, i.e.:
# python ccc2im.py | xmllint --format - > myputput.xml

ET.dump(xml_data)

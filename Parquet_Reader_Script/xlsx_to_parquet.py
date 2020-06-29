#!/usr/bin/python3

import sys
import pandas as pd
#var_excel_file="Financial_Sample.xlsx"                                                                                 
#var_parquet_file="Financial_Sample.parquet"
#converting a csv file to parquet using python
df= pd.read_excel(sys.argv[1])
df.to_parquet(sys.argv[2], compression=None)
exit()

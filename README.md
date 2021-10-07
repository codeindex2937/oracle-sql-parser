# Oracle SQL Parser
this is an oracle sql parser. ref: https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf

## supported statement
|statement| sub statement |yacc|ast|
|----|----|----|----|
|Alter table|Add column| :heavy_check_mark:|:heavy_check_mark:|
|Alter table|Modify column| :heavy_check_mark:|:heavy_check_mark:|
|Alter table|Drop column| :heavy_check_mark:|:heavy_check_mark:|
|Alter table|Rename column| :heavy_check_mark:|:heavy_check_mark:|
|Create table|Relational table|:heavy_check_mark:| |
## usage
```go
package main

import (
	"fmt"
	"github.com/sjjian/oracle_sql_parser"
	"github.com/sjjian/oracle_sql_parser/ast"
)

func main() {
	stmts, err := parser.Parser("alter table db1.t1 add (id number, name varchar2(255))")
	if err != nil {
		fmt.Println(err)
		return
	}
	stmt := stmts[0]
	switch s := stmt.(type) {
	case *ast.AlterTableStmt:
		fmt.Println(s.TableName.Table.Value) // t1
	}
}
```

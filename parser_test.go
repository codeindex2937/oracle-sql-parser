package parser

import (
	"github.com/sjjian/oracle_sql_parser/ast"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestParseAlterTable(t *testing.T) {
	querys := []string{
		`
alter table db1.table1 add (id number)
`,
		`
alter table db1.table1 add (id number, name varchar(255))
`,
		`
alter table db1.table1 add (id number(*))
`,
		`
alter table db1.table1 add (id number(5));
`,
		`
alter table db1.table1 add (id number(5, 3));
`,
		`
alter table db1.table1 add (id float(*))
`,
		`
alter table db1.table1 add (id float(5))
`,
		`
alter table db1.table1 add (id varchar2(255))
`,
		`
alter table db1.table1 add (id varchar2(255) collate binary_ci) 
`,
		`
alter table db1.table1 add (id varchar2(255) sort) 
`,
		`
alter table db1.table1 add (id varchar2(255) collate binary_ci sort) 
`,
		`
alter table db1.table1 add (id varchar2(255) collate binary_ci invisible) 
`,
		`
alter table db1.table1 add (id varchar2(255) collate binary_ci  visible) 
`,
		`
alter table db1.table1 add (id varchar2(255) collate binary_ci sort invisible) 
`,
		`
alter table db1.table1 add (id varchar2(255) default "test") 
`,
		`
alter table db1.table1 add (id number default 123) 
`,
		`
alter table db1.table1 modify (id varchar2(255))
`,
		`
alter table db1.table1 modify (id varchar2(255) default "123")
`,
		`
alter table db1.table1 drop column id
`,
		`
alter table db1.table1 drop (id,name)
`,
		`
alter table db1.table1 set unused column id
`,
		`
alter table db1.table1 rename column id to new_id
`,
	}
	for _, query := range querys {
		stmt, err := Parser(query)
		assert.NoError(t, err, "query: %s", query)
		assert.IsType(t, &ast.AlterTableStmt{}, stmt)
	}
}

func TestParseCreateTableStmt(t *testing.T) {
	querys := []string{
		`
create table db1.table1 (id number(10));
`,
		`
create table db1.table1 (id number(10), name varchar2(255));
`,
	}
	for _, query := range querys {
		stmt, err := Parser(query)
		assert.NoError(t, err, "query: %s", query)
		assert.IsType(t, &ast.CreateTableStmt{}, stmt)
	}
}

package parser

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
	"testing"

	"github.com/codeindex2937/oracle-sql-parser/ast"
	"github.com/codeindex2937/oracle-sql-parser/ast/element"
	"github.com/stretchr/testify/assert"
)

func TestParserSQLCoverage(t *testing.T) {
	path := "./test"
	files, err := ioutil.ReadDir(path)
	if err != nil {
		t.Error(err)
		return
	}
	for _, f := range files {
		fmt.Printf("test sql file %s\n", f.Name())
		if !strings.HasSuffix(f.Name(), ".sql") {
			continue
		}
		data, err := ioutil.ReadFile(filepath.Join(path, f.Name()))
		if err != nil {
			t.Error(err)
			return
		}
		query := string(data)
		stmts, err := Parser(query)
		if err != nil {
			t.Error(err)
			return
		}
		for _, stmt := range stmts {
			assert.NotNil(t, stmt)
			assert.Equal(t, len(stmt.Text()) > 0, true)
		}
	}
}

func TestSingleQuery(t *testing.T) {
	stmt, err := Parser(`create table db1.table1 (id number(10))`)
	assert.NoError(t, err)
	assert.Equal(t, 1, len(stmt))
	assert.IsType(t, &ast.CreateTableStmt{}, stmt[0])
	assert.Equal(t, `create table db1.table1 (id number(10))`, stmt[0].Text())

	stmt, err = Parser(`create table db1.table1 (id number(10));`)
	assert.NoError(t, err)
	assert.Equal(t, 1, len(stmt))
	assert.IsType(t, &ast.CreateTableStmt{}, stmt[0])
	assert.Equal(t, `create table db1.table1 (id number(10));`, stmt[0].Text())
}

func TestMultiQuery(t *testing.T) {
	stmt, err := Parser(`create table db1.table1 (id number(10));
alter table db1.table1 add (name varchar(255))`)
	assert.NoError(t, err)
	assert.Equal(t, 2, len(stmt))
	assert.IsType(t, &ast.CreateTableStmt{}, stmt[0])
	assert.Equal(t, "create table db1.table1 (id number(10));", stmt[0].Text())
	assert.IsType(t, &ast.AlterTableStmt{}, stmt[1])
	assert.Equal(t, "alter table db1.table1 add (name varchar(255))", stmt[1].Text())

	stmt, err = Parser(`create table db1.table1 (id number(10));
alter table db1.table1 add (name varchar(255));`)
	assert.NoError(t, err)
	assert.Equal(t, 2, len(stmt))
	assert.IsType(t, &ast.CreateTableStmt{}, stmt[0])
	assert.Equal(t, "create table db1.table1 (id number(10));", stmt[0].Text())
	assert.IsType(t, &ast.AlterTableStmt{}, stmt[1])
	assert.Equal(t, "alter table db1.table1 add (name varchar(255));", stmt[1].Text())
}

func TestTableComment(t *testing.T) {
	stmt, err := Parser(`comment on table tbl is 'a';comment on TABLE s1.tb2 is 'a'`)
	assert.NoError(t, err)
	assert.Equal(t, 2, len(stmt))
	assert.IsType(t, &ast.CommentStmt{}, stmt[0])
	assert.Equal(t, "comment on table tbl is 'a'", stmt[0].Text())
	assert.Equal(t, ast.CommentOnTable, stmt[0].(*ast.CommentStmt).Type)
	assert.Equal(t, (*element.Identifier)(nil), stmt[0].(*ast.CommentStmt).TableName.Schema)
	assert.Equal(t, "tbl", stmt[0].(*ast.CommentStmt).TableName.Table.Value)
	assert.Equal(t, "a", stmt[0].(*ast.CommentStmt).Comment)
	assert.IsType(t, &ast.CommentStmt{}, stmt[1])
	assert.Equal(t, ";comment on TABLE s1.tb2 is 'a'", stmt[1].Text())
	assert.Equal(t, ast.CommentOnTable, stmt[1].(*ast.CommentStmt).Type)
	assert.Equal(t, "s1", stmt[1].(*ast.CommentStmt).TableName.Schema.Value)
	assert.Equal(t, "tb2", stmt[1].(*ast.CommentStmt).TableName.Table.Value)
	assert.Equal(t, "a", stmt[1].(*ast.CommentStmt).Comment)
}

func TestColumnComment(t *testing.T) {
	stmt, err := Parser(`comment on column tbl."year" is 'a';comment on COLUMN s1.tb1.col2 is 'li''ne1
 	line2'`)
	assert.NoError(t, err)
	assert.Equal(t, 2, len(stmt))
	if len(stmt) != 2 {
		return
	}

	assert.IsType(t, &ast.CommentStmt{}, stmt[0])
	assert.Equal(t, "comment on column tbl.\"year\" is 'a';", stmt[0].Text())
	assert.Equal(t, ast.CommentOnColumn, stmt[0].(*ast.CommentStmt).Type)
	assert.Equal(t, (*element.Identifier)(nil), stmt[0].(*ast.CommentStmt).TableName.Schema)
	assert.Equal(t, "tbl", stmt[0].(*ast.CommentStmt).TableName.Table.Value)
	assert.Equal(t, "year", stmt[0].(*ast.CommentStmt).ColumnName.Value)
	assert.Equal(t, "a", stmt[0].(*ast.CommentStmt).Comment)
	assert.IsType(t, &ast.CommentStmt{}, stmt[1])
	assert.Equal(t, "comment on COLUMN s1.tb1.col2 is 'li''ne1\n 	line2'", stmt[1].Text())
	assert.Equal(t, ast.CommentOnColumn, stmt[1].(*ast.CommentStmt).Type)
	assert.Equal(t, "s1", stmt[1].(*ast.CommentStmt).TableName.Schema.Value)
	assert.Equal(t, "tb1", stmt[1].(*ast.CommentStmt).TableName.Table.Value)
	assert.Equal(t, "col2", stmt[1].(*ast.CommentStmt).ColumnName.Value)
	assert.Equal(t, "li'ne1\n 	line2", stmt[1].(*ast.CommentStmt).Comment)
}

func TestCreateSeuenceStmt(t *testing.T) {
	_, err := Parser(`CREATE SEQUENCE ABC.SEQ INCREMENT BY 1 START WITH 1 MAXVALUE 999999999 CYCLE NOORDER`)
	assert.NoError(t, err)
}

func TestTableReference(t *testing.T) {
	stmt, err := Parser(`CREATE TABLE MINOR (CONSTRAINT fk_name FOREIGN KEY (ID1,ID2) REFERENCES MAJOR(ID3,ID4) ON UPDATE CASCADE ON DELETE CASCADE);`)
	assert.NoError(t, err)
	assert.Equal(t, 1, len(stmt))
	assert.IsType(t, &ast.CreateTableStmt{}, stmt[0])
	assert.Equal(t, "CREATE TABLE MINOR (CONSTRAINT fk_name FOREIGN KEY (ID1,ID2) REFERENCES MAJOR(ID3,ID4) ON UPDATE CASCADE ON DELETE CASCADE);", stmt[0].Text())
	assert.Equal(t, 1, len(stmt[0].(*ast.CreateTableStmt).RelTable.TableStructs))

	assert.IsType(t, &ast.OutOfLineConstraint{}, stmt[0].(*ast.CreateTableStmt).RelTable.TableStructs[0])
	tbl := stmt[0].(*ast.CreateTableStmt).RelTable.TableStructs[0].(*ast.OutOfLineConstraint)
	assert.IsType(t, 2, len(tbl.Columns))
	assert.IsType(t, "ID3", tbl.Columns[0].Value)
	assert.IsType(t, "ID4", tbl.Columns[1].Value)
	assert.IsType(t, "MAJOR", tbl.Reference.Table.Table.Value)
	assert.IsType(t, 2, len(tbl.Reference.Columns))
	assert.IsType(t, "ID1", tbl.Reference.Columns[0].Value)
	assert.IsType(t, "ID2", tbl.Reference.Columns[1].Value)
	assert.IsType(t, ast.RefOptCascade, tbl.DeleteAction.Type)
	assert.IsType(t, ast.RefOptCascade, tbl.UpdateAction.Type)
}

func TestIgnoreTableCheckConstraint(t *testing.T) {
	_, err := Parser(`CREATE TABLE TBL (CONSTRAINT c CHECK (ID5 IS NOT NULL))`)
	assert.NoError(t, err)
}

func TestIgnoreTableIndexSorted(t *testing.T) {
	_, err := Parser(`CREATE SEQUENCE ABC.SEQ INCREMENT BY 1 START WITH 1 MAXVALUE 999999999 CYCLE NOORDER`)
	assert.NoError(t, err)
}

func TestIgnoreGrantStatement(t *testing.T) {
	_, err := Parser(`GRANT SELECT,DELETE,UPDATE,INSERT ON ABC.TBL3 TO SOMEONE`)
	assert.NoError(t, err)
}

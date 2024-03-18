SELECT UPPER(TABLE_NAME) AS "테이블 영문명"
	, UPPER(COLUMN_NAME) AS "컬럼 영문명"
	, col_kor_name  AS "컬럼 한글명"
	, col_kor_name  AS "컬럼 설명"
	, tbl_kor_name  AS "연관 엔터티명"
	, col_kor_name  AS "연관 속성명"
	, CASE WHEN SUBSTRING(data_type,1,4)='varc' THEN 'VARCHAR' 
		WHEN SUBSTRING(data_type,1,4)='bigi' THEN 'BIGINT' 
		WHEN SUBSTRING(data_type,1,4)='doub' THEN 'DOUBLE PRECISION' 
		WHEN SUBSTRING(data_type,1,4)='nume' THEN 'NUMERIC' 
		WHEN SUBSTRING(data_type,1,4)='inte' THEN 'INTEGER' 
		WHEN SUBSTRING(data_type,1,4)='time' AND  data_type = 'timestamp' THEN 'TIMESTAMP'
		WHEN SUBSTRING(data_type,1,4)='time' AND  data_type = 'timestamp with time zone' THEN 'TIMESTAMPZ' 
		WHEN SUBSTRING(data_type,1,4)='USER' THEN 'GEOMETRY' 
		WHEN SUBSTRING(data_type,1,4)='smal' THEN 'SMALLINT' 
		WHEN SUBSTRING(data_type,1,4)='text' THEN 'TEXT' 
		WHEN SUBSTRING(data_type,1,4)='date' THEN 'DATE' 
		WHEN SUBSTRING(data_type,1,4)='char' THEN 'CHAR'
		WHEN SUBSTRING(data_type,1,4)='bool' THEN 'BOOLEAN'  
		WHEN SUBSTRING(data_type,1,4)='real' THEN 'REAL'  
		END AS "데이터 타입"
	, CASE WHEN SUBSTRING(data_type,1,4) ='varc' AND data_type <> 'varchar(0)' THEN replace(REPLACE(data_type,'varchar(',''),')','') 
	WHEN SUBSTRING(data_type,1,4) ='char' AND data_type <> 'char(0)'  THEN replace(REPLACE(data_type,'char(',''),')','') 
	WHEN SUBSTRING(data_type,1,4)='nume' AND data_type <> 'numeric(0,0)' THEN replace(REPLACE(data_type,'numeric(',''),')','') 
	ELSE '  ' 
	END AS "데이터 길이"
	, CASE WHEN SUBSTRING(data_type,1,4) ='time' THEN 'YYYYMMDDHH24MISSFF6' ELSE '  ' END AS "데이터 형식"
	, CASE WHEN "nullable"='NO' THEN 'NOT NULL' ELSE '  '   END AS "Not Null 여부" 
	, CASE WHEN pk_v='PK' THEN 'PK' ELSE '  ' END AS "PK정보" 
	, CASE WHEN fk_v='FK' THEN 'FK' ELSE '  ' END AS "FK정보" 
	, case WHEN b.domainnm is not null then b.domainnm ELSE '  ' end AS "AK정보" 
	,'' AS "제약조건", '' AS "개인정보여부", '' AS "암호화여부" , '비공개 - 업무용 자료' AS "공개/비공개여부" 
--	, CASE WHEN col_kor_name='N' THEN 2 ELSE 1 END ord
FROM 
(
select (select PD.DESCRIPTION 
          from PG_DESCRIPTION      PD
         where PS.RELID         = PD.OBJOID
           and PD.OBJSUBID      = 0) as TBL_KOR_NAME , 
       PC.TABLE_NAME as TABLE_NAME,
       PC.ORDINAL_POSITION Seq_No, 
       (select PD.DESCRIPTION
          from PG_STAT_USER_TABLES PU,
               PG_DESCRIPTION      PD,
               PG_ATTRIBUTE        PA
         where PU.RELID     = PD.OBJOID
           and PD.OBJSUBID  <> 0
           and PD.OBJOID     = PA.ATTRELID
           and PD.OBJSUBID  = PA.ATTNUM
           and PU.RELNAME   = PC.TABLE_NAME
           and PA.ATTNAME   = PC.COLUMN_NAME
           order by PD.OBJOID desc LIMIT 1  ) as COL_KOR_NAME, 
       PC.COLUMN_NAME, 
       case PC.DATA_TYPE
            when 'character'         then 'char' || '(' || PC.CHARACTER_MAXIMUM_LENGTH || ')'
            when 'character varying' then 'varchar' || '(' || COALESCE(PC.CHARACTER_MAXIMUM_LENGTH, 0) || ')'
            when 'text'              then 'text' 
            when 'date'              then 'date' 
            when 'timestamp without time zone'      then 'timestamp'
            when 'timestamp with time zone'         then 'timestamp with time zone'
            when 'numeric'           then 'numeric' || '(' || COALESCE(PC.NUMERIC_PRECISION,0) || ',' || COALESCE(PC.NUMERIC_SCALE,0) || ')'
--            when 'numeric'           then 'numeric' || '(' || PC.NUMERIC_PRECISION || ',' || PC.NUMERIC_SCALE || ')'
            when 'integer'           then 'integer' 
            when 'real'              then 'real'    
            when 'smallint'          then 'smallint' 
            when 'bigserial'         then 'bigserial'
            when 'bigint'            then 'bigint' 
            when 'geometry'          then 'geometry'
            else             PC.DATA_TYPE
       end DATA_TYPE, 
       (select 'PK'              
         from INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC,
              INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CC
        where TC.CONSTRAINT_SCHEMA  = PS.SCHEMANAME
          and TC.TABLE_NAME     = PC.TABLE_NAME
          and TC.CONSTRAINT_TYPE = 'PRIMARY KEY'
          and TC.TABLE_CATALOG  = CC.TABLE_CATALOG
          and TC.TABLE_SCHEMA   = CC.TABLE_SCHEMA
          and TC.TABLE_NAME     = CC.TABLE_NAME
          and TC.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
          and CC.COLUMN_NAME    = PC.COLUMN_NAME
          ) as PK_V,
       (select 'FK' 
         from INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC,
              INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CC
        where TC.CONSTRAINT_SCHEMA  = PS.SCHEMANAME
          and TC.TABLE_NAME     = PC.TABLE_NAME
          and TC.CONSTRAINT_TYPE = 'FOREIGN KEY'
          and TC.TABLE_CATALOG  = CC.TABLE_CATALOG
          and TC.TABLE_SCHEMA   = CC.TABLE_SCHEMA
         -- and TC.TABLE_NAME     = CC.TABLE_NAME
          and TC.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
          and CC.COLUMN_NAME    = PC.COLUMN_NAME
          LIMIT 1) FK_V,
       PC.IS_NULLABLE as NULLABLE-- c.data_default
 from PG_STAT_USER_TABLES PS, INFORMATION_SCHEMA.COLUMNS PC  
 where PS.SCHEMANAME = 'lyr_center'               -- SCHEMA NAME
   and PS.SCHEMANAME = PC.TABLE_SCHEMA
   and PC.TABLE_CATALOG = 'ofbd'            --- DB NAME
 --  and (PS.RELNAME like 'ct_%' or PS.RELNAME like 'ly_%' or PS.RELNAME like 'md_%'
 --    or PS.RELNAME like 'sm_%' or PS.RELNAME like 'st_%' )
   and PS.RELNAME      = PC.TABLE_NAME
) a 
LEFT JOIN PUBLIC.standard0308 b ON upper(a.column_name)=b.engstan AND a.col_kor_name=b.krstan
LEFT JOIN lyr_center_tblist c ON UPPER(a.table_name)=c.tblnm
ORDER BY c.ordcnt
--LIMIT 10
--ORDER BY TABLE_NAME DESC, seq_no
;


select (select PD.DESCRIPTION 
          from PG_DESCRIPTION      PD
         where PS.RELID         = PD.OBJOID
           and PD.OBJSUBID      = 0) as TBL_KOR_NAME , 
       PC.TABLE_NAME as TABLE_NAME,
       PC.ORDINAL_POSITION Seq_No, 
       (select PD.DESCRIPTION
          from PG_STAT_USER_TABLES PU,
               PG_DESCRIPTION      PD,
               PG_ATTRIBUTE        PA
         where PU.RELID     = PD.OBJOID
           and PD.OBJSUBID  <> 0
           and PD.OBJOID     = PA.ATTRELID
           and PD.OBJSUBID  = PA.ATTNUM
           and PU.RELNAME   = PC.TABLE_NAME
           and PA.ATTNAME   = PC.COLUMN_NAME
           order by PD.OBJOID desc LIMIT 1  ) as COL_KOR_NAME, 
       PC.COLUMN_NAME, 
       case PC.DATA_TYPE
            when 'character'         then 'char' || '(' || PC.CHARACTER_MAXIMUM_LENGTH || ')'
            when 'character varying' then 'varchar' || '(' || COALESCE(PC.CHARACTER_MAXIMUM_LENGTH, 0) || ')'
            when 'text'              then 'text' 
            when 'date'              then 'date' 
            when 'timestamp without time zone'      then 'timestamp'
            when 'timestamp with time zone'         then 'timestamp with time zone'
            when 'numeric'           then 'numeric' || '(' || COALESCE(PC.NUMERIC_PRECISION,0) || ',' || COALESCE(PC.NUMERIC_SCALE,0) || ')'
--            when 'numeric'           then 'numeric' || '(' || PC.NUMERIC_PRECISION || ',' || PC.NUMERIC_SCALE || ')'
            when 'integer'           then 'integer' 
            when 'real'              then 'real'    
            when 'smallint'          then 'smallint' 
            when 'bigserial'         then 'bigserial'
            when 'bigint'            then 'bigint' 
            when 'geometry'          then 'geometry'
            else             PC.DATA_TYPE
       end DATA_TYPE, 
       (select 'PK'              
         from INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC,
              INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CC
        where TC.CONSTRAINT_SCHEMA  = PS.SCHEMANAME
          and TC.TABLE_NAME     = PC.TABLE_NAME
          and TC.CONSTRAINT_TYPE = 'PRIMARY KEY'
          and TC.TABLE_CATALOG  = CC.TABLE_CATALOG
          and TC.TABLE_SCHEMA   = CC.TABLE_SCHEMA
          and TC.TABLE_NAME     = CC.TABLE_NAME
          and TC.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
          and CC.COLUMN_NAME    = PC.COLUMN_NAME
          ) as PK_V,
       (select 'FK' 
         from INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC,
              INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CC
        where TC.CONSTRAINT_SCHEMA  = PS.SCHEMANAME
          and TC.TABLE_NAME     = PC.TABLE_NAME
          and TC.CONSTRAINT_TYPE = 'FOREIGN KEY'
          and TC.TABLE_CATALOG  = CC.TABLE_CATALOG
          and TC.TABLE_SCHEMA   = CC.TABLE_SCHEMA
         -- and TC.TABLE_NAME     = CC.TABLE_NAME
          and TC.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
          and CC.COLUMN_NAME    = PC.COLUMN_NAME
          LIMIT 1) FK_V,
       PC.IS_NULLABLE as NULLABLE-- c.data_default
 from PG_STAT_USER_TABLES PS, INFORMATION_SCHEMA.COLUMNS PC  
 where PS.SCHEMANAME = 'lyr_center'               -- SCHEMA NAME
   and PS.SCHEMANAME = PC.TABLE_SCHEMA
   and PC.TABLE_CATALOG = 'ofbd'            --- DB NAME
 --  and (PS.RELNAME like 'ct_%' or PS.RELNAME like 'ly_%' or PS.RELNAME like 'md_%'
 --    or PS.RELNAME like 'sm_%' or PS.RELNAME like 'st_%' )
   and PS.RELNAME      = PC.TABLE_NAME
 --order by PC.TABLE_NAME, PC.ORDINAL_POSITION
-- AND PA.ATTNAME   = 'conc'
 
 ;

declare @cnt          int = 1;
declare @max_row      int;
declare @tbl          nvarchar(max);
declare @col          nvarchar(max);
declare @unique       nvarchar(1);
declare @total_rows   int;
declare @cnt_null     int;
declare @cnt_distinct int;
declare @min_val      nvarchar(max);
declare @max_val      nvarchar(max);

drop table dbo.zzz_data_profiling;

select   row_number() over(order by table_catalog, table_name, column_name) as row 
        ,table_catalog as database_name
        ,table_name
        ,column_name
        ,ordinal_position
        ,data_type
        ,case when character_maximum_length is not null 
              then cast(character_maximum_length as nvarchar)
              else '(' + cast(numeric_precision as nvarchar) + ',' + cast(numeric_scale as nvarchar) + ')' end as length
        ,'N' as unique_ind
        ,cast(0 as int) as total_rows
        ,cast(0 as int) as cnt_null
        ,cast(0 as int) as cnt_distinct
        ,cast('' as nvarchar(max)) as min_val
        ,cast('' as nvarchar(max)) as max_val
into     dbo.zzz_data_profiling
from     INFORMATION_SCHEMA.COLUMNS
where    table_name in ('PB_ACCOUNTS_KYC',
                        'PB_CUSTOMER_ACCOUNT_LINK_KYC',
                        'PB_CUSTOMERS_KYC',
                        'TAMLA_STG_ACCOUNTS_BASE_KYC',
                        'TAMLA_STG_CUSTOMER_ACCOUNTS_LINK_BASE_KYC',
                        'TAMLA_STG_CUSTOMERS_BASE_KYC')
;

select @max_row=max(row) from dbo.zzz_data_profiling;

while @cnt <= @max_row
begin
   
   select @tbl=table_name from dbo.zzz_data_profiling where row = @cnt;
   select @col=column_name from dbo.zzz_data_profiling where row = @cnt;
   
   -- Total Row Count
   exec('update dbo.zzz_data_profiling set total_rows = (select count(*) from dbo.' + @tbl + ') where  row = ' + @cnt + ';'); 
   
   -- Count Null
   exec('update dbo.zzz_data_profiling set cnt_null = (select sum(case when cast([' + @col + '] as nvarchar(max)) = '''' then 1 else 0 end) from dbo.' + @tbl + ') where  row = ' + @cnt + ';'); 

   -- Count Distinct 
   exec('update dbo.zzz_data_profiling set cnt_distinct = (select count(distinct [' + @col +']) from dbo.' + @tbl + ') where  row = ' + @cnt + ';'); 

   -- Min Value
   exec('update dbo.zzz_data_profiling set min_val = (select min([' + @col +']) from dbo.' + @tbl + ') where  row = ' + @cnt + ';'); 

   -- Max Value
   exec('update dbo.zzz_data_profiling set max_val = (select max([' + @col +']) from dbo.' + @tbl + ') where  row = ' + @cnt + ';'); 

   set @cnt = @cnt + 1;
   
end;
   
   -- Unique Indicator
   update dbo.zzz_data_profiling set unique_ind = 'Y' where  total_rows = cnt_distinct;
   
GO
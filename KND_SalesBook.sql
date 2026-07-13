declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select FACTUREID, FACTUREEXTERNALID, ACCOUNTNAME, ACCOUNTNUM, FACTUREDATE, OPERATIONTYPECODES  from SalesBOOKTRANS_RU
join SalesBOOKTABLE_RU
on SalesBOOKTABLE_RU.RECID = SalesBOOKTRANS_RU.SalesBOOKTABLE_RU
where 
SalesBOOKTABLE_RU.ClosingDate >=  @fromdate
and SalesBOOKTABLE_RU.ClosingDate <=  @todate
group by FACTUREID, FACTUREEXTERNALID, ACCOUNTNAME, ACCOUNTNUM, FACTUREDATE, OPERATIONTYPECODES

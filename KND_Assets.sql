declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');


select AssetGroup, AccountNum, Name, AcquisitionDate from RAssetTable

where AcquisitionDate > '01.01.2026'
and AssetGroup in('0102','0106')

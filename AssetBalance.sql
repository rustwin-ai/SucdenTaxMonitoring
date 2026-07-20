declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');


select 
RASUnion.ASSETSTANDARDID as 'Вид учета ОС',
RAT.ASSETGROUP as 'Группа ОС',
RASUnion.AssetGroup as 'Амортизационная группа',
RAT.ACCOUNTNUM as 'Инвентарный номер ОС',
RAT.Name as 'Название',
cast( RAT.AcquisitionDate as date) as 'Дата приобретения',
RASUnion.CurrencyCode as 'Валюта',
cast (RASUnion.Acquisition as money) as 'Первоначальная стоимость',
cast (RASUnion.AcquisitionAdj as money) as 'Переоценка стоимости',
cast (RASUnion.Revaluation as money) as 'Кап. ремонт',
cast (RASUnion.Depreciation as money) as 'Амортизация',
cast (RASUnion.DepreciationAdj as money) as 'Переоценка амортизации',
cast (RASUnion.Acquisition + RASUnion.AcquisitionAdj + RASUnion.Revaluation + RASUnion.Depreciation + RASUnion.DepreciationAdj as money) as 'Остаточная стоимость',
RASUnion.NEWLIFE as 'СПИ'

from RASSETTABLE RAT
join RAssetMainGroup RAMG
on RAMG.ASSETMAINGROUPID = RAT.ASSETGROUP
left join CUSTTABLE CT
on CT.AccountNum = RAT.CUSTACCOUNT
left join DIRPARTYTABLE DPT
on DPT.RecId = CT.PARTY

join (select ASSETID, RAS.AssetStandardId, AssetGroup, DisposalDate, CurrencyCode, t2.Depreciation, t2.DepreciationAdj, t2.Acquisition, t2.AcquisitionAdj,t2.Revaluation, NewLife,  AcquisitionPrice from RAssetStandards RAS
	   
	    join (select AccountNum, AssetStandardId as StandardId,  
		
		SUM (CASE WHEN AssetTransType  in (3) THEN AMOUNTCUR  ELSE 0  END) as  Acquisition,
		SUM (CASE WHEN AssetTransType  in (4) THEN AMOUNTCUR  ELSE 0  END) as  AcquisitionAdj,
		SUM (CASE WHEN AssetTransType  in (2) THEN AMOUNTCUR  ELSE 0  END) as  Revaluation,
		SUM (CASE WHEN AssetTransType  in (0) THEN AMOUNTCUR  ELSE 0  END) as  Depreciation,
		SUM (CASE WHEN AssetTransType  in (1) THEN AMOUNTCUR  ELSE 0  END) as  DepreciationAdj
		from RAssetTrans 
		where RAssetTrans.transDate <= @todate		
		group by AccountNum, AssetStandardId) t2 on RAS.ASSETID = t2.ACCOUNTNUM and RAS.AssetStandardId = t2.StandardId
		
		join RAssetLifeHist RLH on RLH.RECID = (select top 1 RecId from RAssetLifeHist t5 where   RAS.ASSETID = t5.ACCOUNTNUM and RAS.AssetStandardId = t5.ASSETSTANDARDID)
		
		where  RAS.AssetStandardId = N'Фин учет'	
		
		union 
		select ASSETID, RASTAX.AssetStandardId, AssetGroup, DisposalDate, CurrencyCode, t3.Depreciation,t3.DepreciationAdj, t3.Acquisition, t3.AcquisitionAdj, t3.Revaluation,NewLife, AcquisitionPrice from RAssetStandards RASTAX
		
		join (select AccountNum, AssetStandardId as StandardId,
		SUM (CASE WHEN AssetTransType  in (3) THEN AMOUNTCUR  ELSE 0  END) as  Acquisition,
		SUM (CASE WHEN AssetTransType  in (4) THEN AMOUNTCUR  ELSE 0  END) as  AcquisitionAdj,
		SUM (CASE WHEN AssetTransType  in (2) THEN AMOUNTCUR  ELSE 0  END) as  Revaluation,
		SUM (CASE WHEN AssetTransType in (0) THEN AMOUNTCUR  ELSE 0  END) as  Depreciation,
		SUM (CASE WHEN AssetTransType in (1) THEN AMOUNTCUR  ELSE 0  END) as  DepreciationAdj
		from RAssetTrans 
		where RAssetTrans.transDate <= @todate
		group by AccountNum, AssetStandardId) t3 
		on RASTAX.ASSETID = t3.ACCOUNTNUM and RASTAX.AssetStandardId = t3.StandardId

		join RAssetLifeHist RLHTAX on RLHTAX.RECID = (select top 1 RecId from RAssetLifeHist t4 where   RASTAX.ASSETID = t4.ACCOUNTNUM and RASTAX.AssetStandardId = t4.ASSETSTANDARDID)
		where RASTAX.AssetStandardId = N'Налог') RASUnion
		on RASUnion.ASSETID = RAT.ACCOUNTNUM
		and  (RASUnion.DisposalDate > @todate or RASUnion.DisposalDate < '01.01.2016')
where  RAT.ASSETTYPE not in (8,9,10)

order by RAT.ASSETGROUP, RAT.ACCOUNTNUM

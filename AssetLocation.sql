declare @fromdate datetime;
declare @todate datetime;
set @fromdate = parse('__FROMDATE__' as datetime using 'ru');
set @todate = parse('__TODATE__' as datetime using 'ru');

select
    RASSETTABLE.AssetGroup                         as 'Группа ОС',
    RASSETTABLE.accountnum                         as 'Инвентарный номер ОС',
    RASSETTABLE.NAME                               as 'Название',
    dbo.ENUM2STR('RAssetStatus', RASSETTABLE.Status) as 'Статус',
    cast(RASSETTABLE.AcquisitionDate  as date)    as 'Дата приобретения',
    cast(RASSETTABLE.AcquisitionPrice as money)   as 'Стоимость приобретения',

    raStdFin.AssetGroup                           as 'Амортизационная группа (Фин учет)',   -- new
    raStdTax.AssetGroup                           as 'Амортизационная группа (Налог)',      -- new

    DIRPERSONNAME.LASTNAME + ' ' + DIRPERSONNAME.FIRSTNAME + ' ' + DIRPERSONNAME.MIDDLENAME as 'МОЛ',
    RAssetLocation.LOCATION                        as 'Местоположение',
    RAssetLocation.NAME                           as 'Название'

from RASSETTABLE
left join RASSETMOVEHIST
    on RASSETMOVEHIST.RecId = (select TOP 1 RecId from RASSETMOVEHIST
                               where RASSETMOVEHIST.ACCOUNTNUM = RASSETTABLE.accountnum
                                and RASSETMOVEHIST.NEWLOCATION != ''
                               order by ChangeDate desc)
left join RAssetLocation
    on RAssetLocation.LOCATION = RASSETMOVEHIST.NEWLOCATION
left join HCMWORKER
    on HCMWORKER.PERSONNELNUMBER = RASSETMOVEHIST.NEWEMPLOYEE
left join DIRPERSONNAME
    on DIRPERSONNAME.PERSON = HCMWORKER.PERSON
   and DIRPERSONNAME.VALIDTO >= getdate()

-- new: depreciation group per value model
left join RASSETSTANDARDS raStdFin
    on  raStdFin.AssetId        = RASSETTABLE.accountnum
    and raStdFin.AssetStandardId = N'Фин учет'
    and raStdFin.DataAreaId     = RASSETTABLE.DataAreaId
left join RASSETSTANDARDS raStdTax
    on  raStdTax.AssetId        = RASSETTABLE.accountnum
    and raStdTax.AssetStandardId = N'Налог'
    and raStdTax.DataAreaId     = RASSETTABLE.DataAreaId

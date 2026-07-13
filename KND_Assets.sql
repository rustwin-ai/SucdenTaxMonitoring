select AssetGroup, AccountNum, Name, AcquisitionDate from RAssetTable

where AcquisitionDate > '01.01.2026'
and AssetGroup in('0102','0106')

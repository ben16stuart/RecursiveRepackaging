---Select All and run as one query. enable_seqscan set to off forces the query to use indexes and takes about 5-10 seconds. without it 3-6 Mins. this only works if if the indexes exist
SET enable_seqscan TO off;
--explain analyze
WITH RECURSIVE
cte_Repackage (SourcePackageTag, DestinationPackageTag, SourcePackageId, DestinationPackageId, License, ActualDate, Step, Sort)AS
(	-- Anchor member
	Select 
	ts.epc,
	td.epc,
	r.SourcePackageId,
	r.DestinationPackageId,
	l.number,
	r.ActualDate,
	1 as Step,
	CAST(ts.epc as VARCHAR(250))
	FROM metrc.Repackage r
	JOIN metrc.Facility F ON F.Id=r.FacilityId
	JOIN metrc.License L ON L.Id=F.LicenseId
	Join metrc.Package p on p.Id = r.SourcePackageId AND P.id = 26853344
	JOIN metrc.tag ts on ts.packageid = r.SourcePackageId
	JOIN metrc.tag td on td.packageid = r.DestinationPackageId
		
   
	UNION ALL
	-- Recursive member
	Select 
	trs.epc,
	trd.epc,
	r.SourcePackageId,
	r.DestinationPackageId,
	c.License,
	r.ActualDate,
	c.Step + 1,
	cast(c.Sort  || '->' || cast(trs.epc as VARCHAR) as VARCHAR(250))
	FROM cte_Repackage c
	JOIN metrc.Repackage r on r.SourcePackageId = c.DestinationPackageId
	JOIN metrc.tag trs on trs.packageid = r.SourcePackageId
	JOIN metrc.tag trd on trd.packageid = r.DestinationPackageId
)

-- Statement
SELECT
c.DestinationPackageTag,
p.packageddate,
pm.quantitycreated,
pm.quantityremaining,
pm.quantityreceived,
pm.quantitysold,
pm.quantityadjusted,
pm.quantityrepackaged,
pm.quantitytransfered,
uom.abbreviation Quantity_unit_of_measure,
p.productName,
p.productcategoryname,
p.isfinished,
l.license_number current_facility,
l.license_name,
l.dba,
l.physical_address,
l.physical_city,
l.physical_state,
l.physical_zip,
l.aor,
c.Step as Steps,
c.Sort ||'->' || cast(c.DestinationPackageTag as VARCHAR) as Trace

FROM metrc.MVPackage p
JOIN metrc.PackageMetrics pm on pm.packageid = p.id
JOIN cte_Repackage c on p.id = c.DestinationPackageId
JOIN metrc.facility f on f.id = pm.facilityid
JOIN mylo.license l on l.metrc_id = f.LicenseId
JOIN metrc.unitofmeasure uom on uom.id = pm.unitofmeasureid

LIMIT 1000000 --This can sometimes help speed it up

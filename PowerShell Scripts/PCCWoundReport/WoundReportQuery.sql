-- To apply query changes to PowerShell script PccWoundReport
--
-- Copy this SQL script to NotePad ++ (or other text editor)  Do this outside TFS to prevent any accidential check-in's of the following changes.
-- Change All @FacilityID to {0}
--      ###  Change All @ReportDate to {1}  - 10/1/2020 Report Date no longer needed and has been removed from the query
-- Copy all lines starting with and including the line: IF OBJECT_ID('tempdb..#WoundAssessments') IS NOT NULL
--   and replace the query currently in the PS script

DECLARE @FacilityID INT= 96;
IF OBJECT_ID('tempdb..#WoundAssessments') IS NOT NULL
DROP TABLE #WoundAssessments;

CREATE TABLE #WoundAssessments
([AssessmentDate]        DATETIME, 
 [Unit Room-Bed]         VARCHAR(127), 
 [Name]                  VARCHAR(102), 
 [AssessmentID]          INT, 
 [PatientID]             INT, 
 [Onset Date]            DATE, 
 [Admitted or Acquired]  VARCHAR(350), 
 [Location]              VARCHAR(2000), 
 [Type]                  VARCHAR(350), 
 [Stage]                 VARCHAR(350), 
 [DetailsB]              VARCHAR(350), 
 [DetailsC]              VARCHAR(350), 
 [DetailsD]              VARCHAR(350), 
 [DetailsDC]             VARCHAR(2000), 
 [DetailsF]              VARCHAR(2000), 
 [Suspected DTI]         VARCHAR(350), 
 [Length]                VARCHAR(2000), 
 [Width]                 VARCHAR(2000), 
 [Depth]                 VARCHAR(2000), 
 [Undermining/Tunneling] VARCHAR(2000), 
 [Drainage]              VARCHAR(350), 
 [Signs of Infection?]   VARCHAR(350), 
 [Pain?]                 VARCHAR(350), 
 [Treatment]             VARCHAR(2000), 
 [Overall Impression]    VARCHAR(350)
);

INSERT INTO #WoundAssessments
([AssessmentDate], 
 [AssessmentID], 
 [PatientID], 
 [Onset Date], 
 [Admitted or Acquired], 
 [Location], 
 [Type], 
 [Stage], 
 [DetailsB], 
 [DetailsC], 
 [DetailsD], 
 [DetailsDC], 
 [DetailsF], 
 [Suspected DTI], 
 [Length], 
 [Width], 
 [Depth], 
 [Undermining/Tunneling], 
 [Drainage], 
 [Signs of Infection?], 
 [Pain?], 
 [Treatment], 
 [Overall Impression]
)
       SELECT a.AssessmentDate, 
              r.AssessmentID, 
              a.PatientID, 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_1a'
                             THEN r.ItemValue
                         END), '') AS [Onset Date], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_1'
                             THEN r.ItemDesc
                         END), '') AS [Admitted or Acquired], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_2'
                             THEN r.ItemValue
                         END), '') AS [Location], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3'
                             THEN r.ItemDesc
                         END), '') AS [Type], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3a'
                             THEN r.ItemDesc
                         END), '') AS [Stage], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3b'
                             THEN r.ItemDesc
                         END), '') AS [DetailsB], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3c'
                             THEN r.ItemDesc
                         END), '') AS [DetailsC], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3d'
                             THEN r.ItemDesc
                         END), '') AS [DetailsD], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3dc'
                             THEN r.ItemValue
                         END), '') AS [DetailsDC], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3f'
                             THEN r.ItemValue
                         END), '') AS [DetailsF], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_3ae'
                             THEN r.ItemDesc
                         END), '') AS [Suspected DTI], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6a'
                             THEN r.ItemValue
                         END), '') AS [Length], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6b'
                             THEN r.ItemValue
                         END), '') AS [Width], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6c'
                             THEN r.ItemValue
                         END), '') AS [Depth], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_6d'
                             THEN r.ItemValue
                         END), '') AS [Undemining/Tunneling], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_5a'
                             THEN r.ItemDesc
                         END), '') AS [Drainage], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_7a'
                             THEN r.ItemDesc
                         END), '') AS [Signs of Infection?], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_8a'
                             THEN r.ItemDesc
                         END), '') AS [Pain?], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_C_1'
                             THEN r.ItemValue
                         END), '') AS [Treatment], 
              NULLIF(MAX(CASE
                             WHEN r.QuestionKey = 'Cust_B_4a'
                             THEN r.ItemDesc
                         END), '') AS [Overall Impression]
       FROM [dbo].[view_ods_std_assessment_with_responses] AS r WITH(NOLOCK)
            INNER JOIN [dbo].[view_ods_assessment] AS a WITH(NOLOCK) ON a.assessmentid = r.assessmentid
       WHERE a.FacilityID = @FacilityID
             AND r.StdAssessID = 11027
			 AND a.AssessmentDate >= '2020-10-01'
             AND a.Deleted = 'N'
             AND a.AssessmentStatus = 'Complete'
             AND r.QuestionKey IN('Cust_B_1', 'Cust_B_1', 'Cust_B_2', 'Cust_B_3', 'Cust_B_3a', 'cust_B_3b', 'cust_B_3c', 'cust_B_3d', 'cust_B_3dc', 'cust_B_3f', 'Cust_B_6a', 'Cust_B_6b', 'Cust_B_6c', 'Cust_B_6d', 'Cust_B_5a', 'Cust_B_7a', 'Cust_B_8a', 'Cust_B_8a1', 'Cust_C_1', 'Cust_B_4a', 'Cust_B_1a', 'Cust_B_3ae')
       GROUP BY r.AssessmentID, 
                a.PatientID, 
                a.AssessmentDate;

delete from #WoundAssessments
where [Overall Impression] = 'Healed/Resolved'

UPDATE #WoundAssessments
  SET 
      Name = concat(p.LastName, ', ', p.FirstName)
FROM [dbo].[view_ods_facility_patient] p WITH(NOLOCK)
     INNER JOIN #WoundAssessments w ON p.PatientID = w.PatientID
WHERE p.FacilityID = @FacilityID;

UPDATE #WoundAssessments
  SET 
      [Unit Room-Bed] = concat(unit.unitdescription, ' ', room.roomdescription, '-', bed.beddesc)
FROM #woundassessments w
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_patient_census] AS census WITH(NOLOCK) ON census.PatientID = w.PatientID -- = census.patientid
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_bed] AS bed WITH(NOLOCK) ON bed.BedId = census.BedID -- = bed.BedID
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_unit] AS unit WITH(NOLOCK) ON unit.UnitID = bed.UnitID
     INNER JOIN [PCCDataRelay].[dbo].[view_ods_room] AS room WITH(NOLOCK) ON room.RoomID = bed.RoomID
WHERE unit.facilityid = @FacilityID
      AND bed.facilityid = @FacilityID
	  and cencus.EndEffectiveDate is null;

SELECT --[AssessmentId], 
[AssessmentDate], 
[Unit Room-Bed], 
[Name], 
[Onset Date], 
[Admitted or Acquired], 
[Location], 
[Type], 
[Stage/Category], 
[Length], 
[Width], 
[Depth], 
[Undermining/Tunneling], 
[Drainage], 
[Signs of Infection?], 
[Pain?], 
[Treatment], 
[Overall Impression]
FROM
(
    SELECT [AssessmentID], 
           CONVERT(DATE, [AssessmentDate]) AS [AssessmentDate], 
           [Unit Room-Bed], 
           [Name], 
           CONVERT(DATE, [Onset Date]) AS [Onset Date], 
           [Admitted or Acquired], 
           [Location], 
           [Type], 
           LTRIM(Replace(CONCAT([Stage], [Suspected DTI], [DetailsB], [DetailsC], Replace([DetailsD], 'Other', 'Other: '), [DetailsDC], [DetailsF]), 'Unstageable', '')) AS [Stage/Category], 
           [Length], 
           [Width], 
           [Depth], 
           [Undermining/Tunneling], 
           [Drainage], 
           [Signs of Infection?], 
           [Pain?], 
           [Treatment], 
           [Overall Impression], 
           ROW_NUMBER() OVER(PARTITION BY w.name, 
                                          w.location ORDER BY w.assessmentdate DESC) AS rank
    FROM #WoundAssessments w
         INNER JOIN view_ods_patient_census c WITH(NOLOCK) ON w.patientid = c.patientid
    WHERE c.FacilityId = @FacilityID
          AND c.censusid IN
    (
        SELECT CensusID
        FROM
        (
            SELECT CensusID, 
                   ROW_NUMBER() OVER(PARTITION BY PATIENTID ORDER BY ISNULL(endeffectivedate, '9999-12-31') DESC) AS Row#
            FROM view_ods_patient_census WITH(NOLOCK)
            WHERE facilityid = @FacilityID
                  AND endeffectivedate IS NULL
        ) A
        WHERE Row# = 1
    )
) x
WHERE x.rank = 1
ORDER BY name, 
         AssessmentDate DESC;

DROP TABLE #WoundAssessments;

SELECT
  eventTime,
  eventName,
  errorCode,
  errorMessage,
  userIdentity.arn,
  userIdentity.sessionContext.sessionIssuer.userName AS roleName,
  sourceIPAddress
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE errorCode IN ('AccessDenied', 'UnauthorizedAccess', 'Client.UnauthorizedAccess')
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 20;

SELECT
  eventTime,
  awsRegion,
  eventName,
  errorCode,
  userIdentity.arn,
  sourceIPAddress
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE errorCode IS NOT NULL
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY awsRegion, eventTime DESC
LIMIT 30;


SELECT
  eventTime,
  eventName,
  userIdentity.arn,
  requestParameters,
  responseElements
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE eventSource = 'iam.amazonaws.com'
  AND eventName LIKE '%Policy%'
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 20;


SELECT
  eventTime,
  eventName,
  sourceIPAddress,
  userAgent,
  awsRegion
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE userIdentity.type = 'Root'
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 10;


SELECT
  eventTime,
  sourceIPAddress,
  userIdentity.arn,
  responseElements
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE eventName = 'ConsoleLogin'
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 10;


SELECT
  eventTime,
  eventName,
  eventSource,
  errorCode,
  userIdentity.arn,
  sourceIPAddress
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE eventSource IN ('secretsmanager.amazonaws.com', 'kms.amazonaws.com')
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 20;


SELECT
  eventTime,
  eventName,
  errorCode,
  userIdentity.arn,
  requestParameters
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE eventSource = 's3.amazonaws.com'
  AND eventName LIKE '%Bucket%'
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 20;


SELECT
  eventSource,
  eventName,
  errorCode,
  COUNT(*) AS eventCount
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE errorCode IS NOT NULL
  AND eventTime > '2026-03-17 00:00:00'
GROUP BY eventSource, eventName, errorCode
ORDER BY eventCount DESC
LIMIT 30;


SELECT
  userIdentity.arn,
  COUNT(*) AS failedCalls
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE errorCode IS NOT NULL
  AND eventTime > '2026-03-17 00:00:00'
GROUP BY userIdentity.arn
ORDER BY failedCalls DESC
LIMIT 10;


SELECT
  sourceIPAddress,
  COUNT(*) AS failedCalls,
  COUNT(DISTINCT eventName) AS uniqueActions,
  COUNT(DISTINCT awsRegion) AS regionsTargeted
FROM 927f7e82-b89a-4fac-9820-68bfa2a7e8bc
WHERE errorCode IS NOT NULL
  AND eventTime > '2026-03-17 00:00:00'
GROUP BY sourceIPAddress
ORDER BY failedCalls DESC
LIMIT 10;

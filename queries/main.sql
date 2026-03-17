-- Replace <EVENT_DATA_STORE_ID> with your CloudTrail Lake event data store ID.
-- Find it with: aws cloudtrail list-event-data-stores --query 'EventDataStores[].EventDataStoreArn'
-- Use only the UUID portion (after eventdatastore/).

SELECT
  eventTime,
  eventName,
  errorCode,
  errorMessage,
  userIdentity.arn,
  userIdentity.sessionContext.sessionIssuer.userName AS roleName,
  sourceIPAddress
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
WHERE userIdentity.type = 'Root'
  AND eventTime > '2026-03-17 00:00:00'
ORDER BY eventTime DESC
LIMIT 10;


SELECT
  eventTime,
  sourceIPAddress,
  userIdentity.arn,
  responseElements
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
WHERE errorCode IS NOT NULL
  AND eventTime > '2026-03-17 00:00:00'
GROUP BY eventSource, eventName, errorCode
ORDER BY eventCount DESC
LIMIT 30;


SELECT
  userIdentity.arn,
  COUNT(*) AS failedCalls
FROM <EVENT_DATA_STORE_ID>
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
FROM <EVENT_DATA_STORE_ID>
WHERE errorCode IS NOT NULL
  AND eventTime > '2026-03-17 00:00:00'
GROUP BY sourceIPAddress
ORDER BY failedCalls DESC
LIMIT 10;

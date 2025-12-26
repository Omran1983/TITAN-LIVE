SELECT *
FROM employers
WHERE created_at > NOW() - INTERVAL '30 days';

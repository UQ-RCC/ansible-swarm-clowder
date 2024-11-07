ALTER TABLE dataset ALTER COLUMN received TYPE timestamp with time zone USING received AT TIME ZONE 'UTC';
ALTER TABLE dataset ALTER COLUMN finished TYPE timestamp with time zone USING finished AT TIME ZONE 'UTC';
ALTER TABLE dataset ALTER COLUMN modified TYPE timestamp with time zone USING modified AT TIME ZONE 'UTC';
ALTER TABLE dataset ALTER COLUMN received SET DEFAULT timezone('UTC', now());
ALTER TABLE file ALTER COLUMN modified TYPE timestamp with time zone USING modified AT TIME ZONE 'UTC';
ALTER TABLE file ALTER COLUMN finished TYPE timestamp with time zone USING finished AT TIME ZONE 'UTC';
ALTER TABLE file ALTER COLUMN received TYPE timestamp with time zone USING received AT TIME ZONE 'UTC';
ALTER TABLE file ALTER COLUMN received SET DEFAULT timezone('UTC', now());

ALTER TABLE dailytask ALTER COLUMN start TYPE timestamp with time zone USING start AT TIME ZONE 'UTC';
ALTER TABLE dailytask ALTER COLUMN start SET DEFAULT timezone('UTC', now());
ALTER TABLE dailytask ALTER COLUMN finished TYPE timestamp with time zone USING finished AT TIME ZONE 'UTC';
ALTER TABLE collection ALTER COLUMN lastupdated TYPE timestamp with time zone USING lastupdated AT TIME ZONE 'UTC';
ALTER TABLE collectioncache ALTER COLUMN lastupdated TYPE timestamp with time zone USING lastupdated AT TIME ZONE 'UTC';

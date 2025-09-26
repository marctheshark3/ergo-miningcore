-- PostgreSQL Database Initialization for Ergo Mining Pool
-- This script sets up the database with proper permissions and complete schema

\echo 'Setting up Ergo Mining Pool database...'

-- Create the miningcore user if it doesn't exist
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles 
      WHERE  rolname = 'miningcore') THEN
      
      CREATE ROLE miningcore WITH LOGIN ENCRYPTED PASSWORD 'changeme123';
   END IF;
END
$do$;

-- Create the database if it doesn't exist
SELECT 'CREATE DATABASE miningcore OWNER miningcore'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'miningcore')\gexec

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE miningcore TO miningcore;

-- Connect to the miningcore database
\c miningcore;

-- Set role for table creation
SET ROLE miningcore;

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO miningcore;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO miningcore;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO miningcore;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO miningcore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO miningcore;

-- Create shares table
CREATE TABLE IF NOT EXISTS shares
(
	poolid TEXT NOT NULL,
	blockheight BIGINT NOT NULL,
	difficulty DOUBLE PRECISION NOT NULL,
	networkdifficulty DOUBLE PRECISION NOT NULL,
	miner TEXT NOT NULL,
	worker TEXT NULL,
	useragent TEXT NULL,
	ipaddress TEXT NOT NULL,
    source TEXT NULL,
	created TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS IDX_SHARES_POOL_MINER on shares(poolid, miner);
CREATE INDEX IF NOT EXISTS IDX_SHARES_POOL_CREATED ON shares(poolid, created);
CREATE INDEX IF NOT EXISTS IDX_SHARES_POOL_MINER_DIFFICULTY on shares(poolid, miner, difficulty);

-- Create blocks table
CREATE TABLE IF NOT EXISTS blocks
(
	id BIGSERIAL NOT NULL PRIMARY KEY,
	poolid TEXT NOT NULL,
	blockheight BIGINT NOT NULL,
	networkdifficulty DOUBLE PRECISION NOT NULL,
	status TEXT NOT NULL,
    type TEXT NULL,
    confirmationprogress FLOAT NOT NULL DEFAULT 0,
	effort FLOAT NULL,
	transactionconfirmationdata TEXT NOT NULL,
	miner TEXT NULL,
	reward decimal(28,12) NULL,
    source TEXT NULL,
    hash TEXT NULL,
	created TIMESTAMPTZ NOT NULL,

    CONSTRAINT BLOCKS_POOL_HEIGHT UNIQUE (poolid, blockheight, type) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX IF NOT EXISTS IDX_BLOCKS_POOL_BLOCK_STATUS on blocks(poolid, blockheight, status);

-- Create balances table
CREATE TABLE IF NOT EXISTS balances
(
	poolid TEXT NOT NULL,
	address TEXT NOT NULL,
	amount decimal(28,12) NOT NULL DEFAULT 0,
	created TIMESTAMPTZ NOT NULL,
	updated TIMESTAMPTZ NOT NULL,

	primary key(poolid, address)
);

-- Create balance_changes table
CREATE TABLE IF NOT EXISTS balance_changes
(
	id BIGSERIAL NOT NULL PRIMARY KEY,
	poolid TEXT NOT NULL,
	address TEXT NOT NULL,
	amount decimal(28,12) NOT NULL DEFAULT 0,
	usage TEXT NULL,
    tags text[] NULL,
	created TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS IDX_BALANCE_CHANGES_POOL_ADDRESS_CREATED on balance_changes(poolid, address, created desc);
CREATE INDEX IF NOT EXISTS IDX_BALANCE_CHANGES_POOL_TAGS on balance_changes USING gin (tags);

-- Create miner_settings table
CREATE TABLE IF NOT EXISTS miner_settings
(
	poolid TEXT NOT NULL,
	address TEXT NOT NULL,
	paymentthreshold decimal(28,12) NOT NULL,
	created TIMESTAMPTZ NOT NULL,
	updated TIMESTAMPTZ NOT NULL,

	primary key(poolid, address)
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments
(
	id BIGSERIAL NOT NULL PRIMARY KEY,
	poolid TEXT NOT NULL,
	coin TEXT NOT NULL,
	address TEXT NOT NULL,
	amount decimal(28,12) NOT NULL,
	transactionconfirmationdata TEXT NOT NULL,
	created TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS IDX_PAYMENTS_POOL_COIN_WALLET on payments(poolid, coin, address);

-- Create poolstats table (this was missing!)
CREATE TABLE IF NOT EXISTS poolstats
(
	id BIGSERIAL NOT NULL PRIMARY KEY,
	poolid TEXT NOT NULL,
	connectedminers INT NOT NULL DEFAULT 0,
	poolhashrate DOUBLE PRECISION NOT NULL DEFAULT 0,
	sharespersecond DOUBLE PRECISION NOT NULL DEFAULT 0,
	networkhashrate DOUBLE PRECISION NOT NULL DEFAULT 0,
	networkdifficulty DOUBLE PRECISION NOT NULL DEFAULT 0,
	lastnetworkblocktime TIMESTAMPTZ NULL,
    blockheight BIGINT NOT NULL DEFAULT 0,
    connectedpeers INT NOT NULL DEFAULT 0,
	created TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS IDX_POOLSTATS_POOL_CREATED on poolstats(poolid, created);

-- Create minerstats table
CREATE TABLE IF NOT EXISTS minerstats
(
	id BIGSERIAL NOT NULL PRIMARY KEY,
	poolid TEXT NOT NULL,
	miner TEXT NOT NULL,
	worker TEXT NOT NULL,
	hashrate DOUBLE PRECISION NOT NULL DEFAULT 0,
	sharespersecond DOUBLE PRECISION NOT NULL DEFAULT 0,
	created TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS IDX_MINERSTATS_POOL_CREATED on minerstats(poolid, created);
CREATE INDEX IF NOT EXISTS IDX_MINERSTATS_POOL_MINER_CREATED on minerstats(poolid, miner, created);
CREATE INDEX IF NOT EXISTS IDX_MINERSTATS_POOL_MINER_WORKER_CREATED_HASHRATE on minerstats(poolid,miner,worker,created desc,hashrate);

\echo 'Database schema created successfully!'
\echo 'All required tables have been initialized and are ready for use.' 
-- PostgreSQL Database Initialization for Ergo Mining Pool
-- This script sets up the database with proper permissions and schema

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

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO miningcore;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO miningcore;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO miningcore;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO miningcore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO miningcore;

\echo 'Database initialization completed successfully!'
\echo 'Note: The miningcore application will create the necessary tables on first run.' 
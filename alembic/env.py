from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
import os
 
# Import your models' Base
from models.models import Base  # <-- make sure path is correct
 
# This is the Alembic Config object
config = context.config
 
# Interpret the config file for Python logging
fileConfig(config.config_file_name)
 
# Tell Alembic about your models' metadata
target_metadata = Base.metadata
 
def run_migrations_offline():
    """Run migrations in 'offline' mode."""
    url = os.getenv("DATABASE_URL") or config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,  # detect column type changes
    )
 
    with context.begin_transaction():
        context.run_migrations()
 
def run_migrations_online():
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
 
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
 
        with context.begin_transaction():
            context.run_migrations()
 
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
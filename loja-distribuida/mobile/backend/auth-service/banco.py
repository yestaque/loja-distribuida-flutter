from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker



DATABASE_URL=("postgresql://admin:123456@postgres-loja:5432/loja"
)


engine = create_engine(
    DATABASE_URL
)


Session = sessionmaker(
    bind=engine
)
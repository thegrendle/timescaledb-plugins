rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    && if [[ -n "$( ls $(pg_config --pkglibdir)/timescaledb-tsl-1*.so )" ]]; then rm -f $(ls -1 $( pg_config --pkglibdir)/timescaledb-tsl-1*.so | head -n -5 ); fi \
    && if [[ -n "$( ls $(pg_config --pkglibdir)/timescaledb-1*.so )" ]]; then rm -f $(ls -1 $( pg_config --pkglibdir)/timescaledb-*.so | head -n -5 ); fi \
    && if [[ -n "$( ls $(pg_config --sharedir)/extension/timescaledb--1*.sql )" ]]; then rm -f $( ls -1 $(pg_config --sharedir)/extension/timescaledb--1*.sql | head -n -5 ); fi

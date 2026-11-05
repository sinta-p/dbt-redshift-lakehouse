{% materialization s3tables_iceberg, adapter='redshift' %}
    {% set target_relation = this.incorporate(type='table') %}

    {# Iceberg DDL cannot run inside a multi-statement transaction. #}
    {% for hook in pre_hooks + post_hooks %}
        {% if hook.get('transaction', true) %}
            {% do exceptions.raise_compiler_error(
                's3tables_iceberg requires hooks configured with transaction: false.'
            ) %}
        {% endif %}
    {% endfor %}
    {% if config.get('contract').enforced %}

        {% do exceptions.raise_compiler_error('s3tables_iceberg does not support enforced contracts yet.') %}
    {% endif %}
    {% if config.get('grants', {}) %}
        {% do exceptions.raise_compiler_error('Manage S3 Tables grants outside this materialization.') %}
    {% endif %}

    {# Prevent a configured output from replacing a declared input source. #}
    {% for source_node in graph.sources.values() %}
        {% if source_node.database == target_relation.database
              and source_node.schema == target_relation.schema
              and source_node.identifier == target_relation.identifier %}
            {% do exceptions.raise_compiler_error('Refusing to replace a declared source: ' ~ target_relation) %}
        {% endif %}
    {% endfor %}

    {{ run_hooks(pre_hooks, inside_transaction=false) }}
    {% do log('Rebuilding Iceberg table ' ~ target_relation ~ ' outside a transaction (drop/create is not atomic).', info=true) %}

    {% call statement('drop_existing', fetch_result=false, auto_begin=false) %}
        drop table if exists {{ target_relation }}
    {% endcall %}
    {% do adapter.cache_dropped(target_relation) %}

    {% call statement('main', fetch_result=false, auto_begin=false) %}
        create table {{ target_relation }}
        using iceberg
        as
        {{ sql }}
    {% endcall %}

    {{ run_hooks(post_hooks, inside_transaction=false) }}
    {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}

select set_id, master.no_comment as master, 
    array_to_string(array_agg(replicas.no_comment), ',') as replicas,
    set_comment as replication_desc
from sl_set 
join sl_node as master on set_origin = no_id 
join sl_subscribe ON set_id = sub_set
join sl_node as replicas ON sub_receiver = replicas.no_id
where sub_active
    and replicas.no_active
group by set_id, master.no_comment, set_comment
order by set_id;
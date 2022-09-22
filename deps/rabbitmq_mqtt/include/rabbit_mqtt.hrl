%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2020-2023 VMware, Inc. or its affiliates.  All rights reserved.
%%

-define(CLIENT_ID_MAXLEN, 23).

-include("rabbit_mqtt_types.hrl").

%% reader state
-record(state, {socket,
                conn_name,
                await_recv,
                deferred_recv,
                received_connect_frame,
                connection_state,
                conserve,
                parse_state,
                proc_state,
                stats_timer,
                keepalive}).

-record(keepalive, {timer :: reference(),
                    interval_ms :: pos_integer(),
                    recv_oct :: non_neg_integer(),
                    received :: boolean()}).

%% processor state
-record(proc_state,
        {socket,
         proto_ver :: 3 | 4,
         queue_states = rabbit_queue_type:init() :: rabbit_queue_type:state(),
         subscriptions = #{} :: #{Topic :: binary() => QoS :: 0..2},
         %% Packet IDs published to queues but not yet confirmed.
         unacked_client_pubs = rabbit_mqtt_confirms:init() :: rabbit_mqtt_confirms:state(),
         %% Packet IDs published to MQTT subscribers but not yet acknowledged.
         unacked_server_pubs = #{} :: #{packet_id() => QueueMsgId :: non_neg_integer()},
         %% Packet ID of next PUBLISH packet (with QoS > 0) sent from server to client.
         %% (Not to be confused with packet IDs sent from client to server which can be the
         %% same IDs because client and server assign IDs independently of each other.)
         packet_id = 1 :: packet_id(),
         client_id,
         clean_sess,
         will_msg,
         exchange :: rabbit_exchange:name(),
         ssl_login_name,
         %% Retained messages handler. See rabbit_mqtt_retainer_sup
         %% and rabbit_mqtt_retainer.
         retainer_pid,
         auth_state,
         peer_addr,
         %%TODO remove funs from state
         mqtt2amqp_fun,
         amqp2mqtt_fun,
         register_state,
         conn_name,
         info}).

-type proc_state() :: #proc_state{}.

-record(auth_state, {username,
                     user,
                     vhost,
                     authz_ctx}).

-record(info, {prefetch,
               host,
               port,
               peer_host,
               peer_port,
               proto_human}).

%% does not include vhost: it is used in
%% the table name
-record(retained_message, {topic,
                           mqtt_msg}).

-define(INFO_ITEMS,
    [host,
     port,
     peer_host,
     peer_port,
     protocol,
     frame_max,
     client_properties,
     ssl,
     ssl_protocol,
     ssl_key_exchange,
     ssl_cipher,
     ssl_hash,
     conn_name,
     connection_state,
     connection,
     unacked_client_pubs,
     unacked_server_pubs,
     packet_id,
     client_id,
     clean_sess,
     will_msg,
     exchange,
     ssl_login_name,
     retainer_pid,
     user,
     vhost]).

-define(MQTT_GUIDE_URL, <<"https://rabbitmq.com/mqtt.html">>).

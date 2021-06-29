# Protocol Documentation
<a name="top"></a>

## Table of Contents

- [ondewo/csi/conversation.proto](#ondewo/csi/conversation.proto)
    - [CheckUpstreamHealthResponse](#ondewo.csi.CheckUpstreamHealthResponse)
    - [ListS2sPipelinesRequest](#ondewo.csi.ListS2sPipelinesRequest)
    - [ListS2sPipelinesResponse](#ondewo.csi.ListS2sPipelinesResponse)
    - [S2sPipeline](#ondewo.csi.S2sPipeline)
    - [S2sPipelineId](#ondewo.csi.S2sPipelineId)
    - [S2sStreamRequest](#ondewo.csi.S2sStreamRequest)
    - [S2sStreamResponse](#ondewo.csi.S2sStreamResponse)
    - [SipTrigger](#ondewo.csi.SipTrigger)
  
    - [SipTrigger.SipTriggerType](#ondewo.csi.SipTrigger.SipTriggerType)
  
    - [Conversations](#ondewo.csi.Conversations)
  
- [Scalar Value Types](#scalar-value-types)



<a name="ondewo/csi/conversation.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## ondewo/csi/conversation.proto



<a name="ondewo.csi.CheckUpstreamHealthResponse"></a>

### CheckUpstreamHealthResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| s2t_status | [google.rpc.Status](#google.rpc.Status) |  |  |
| nlu_status | [google.rpc.Status](#google.rpc.Status) |  |  |
| t2s_status | [google.rpc.Status](#google.rpc.Status) |  |  |






<a name="ondewo.csi.ListS2sPipelinesRequest"></a>

### ListS2sPipelinesRequest
The top-level message sent by client to `ListS2sPipelines` endpoint. Currently without arguments.

TODO: add filtering options






<a name="ondewo.csi.ListS2sPipelinesResponse"></a>

### ListS2sPipelinesResponse
The top-level message received from `ListS2sPipelines` endpoint.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| pipelines | [S2sPipeline](#ondewo.csi.S2sPipeline) | repeated | Collection of S2S pipelines of the server. |






<a name="ondewo.csi.S2sPipeline"></a>

### S2sPipeline
The top-level message sent by client to `CreateS2sPipeline` and `UpdateS2sPipeline` endpoints and received from
`GetS2sPipeline` endpoint.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Required. CSI pipeline identifier consisting of S2T, NLU and T2S configuration. ID can be any non-empty string. |
| s2t_pipeline_id | [string](#string) |  | Required. S2T pipeline ID, e.g. "german_general" |
| nlu_project_id | [string](#string) |  | Required. NLU project ID, usually a hash, e.g. "ae33586b-afda-494a-aa73-1af0589cfc56". |
| nlu_language_code | [string](#string) |  | Required. Language code present in the corresponding NLU project, e.g. "de". |
| t2s_pipeline_id | [string](#string) |  | Required. T2S pipeline ID, e.g. "kerstin". |






<a name="ondewo.csi.S2sPipelineId"></a>

### S2sPipelineId
The top-level message sent by client to `GetS2sPipeline` and `DeleteS2sPipeline` endpoints.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Required. CSI pipeline identifier. |






<a name="ondewo.csi.S2sStreamRequest"></a>

### S2sStreamRequest
The top-level message sent by the client to the
`S2sStream` method.

Multiple request messages should be sent in order:

1.  The first message must contain `pipeline_id` and can contain `session_id` or `initial_intent_display_name`.
    The message must not contain `audio` nor `end_of_stream`.

2.  All subsequent messages must contain `audio`. If `end_of_stream` is `true`, the stream is closed.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| pipeline_id | [string](#string) |  | Optional. The CSI pipeline ID specified in the initial request. |
| session_id | [string](#string) |  | Optional. The session or call ID specified in the initial request. It’s up to the API caller to choose an appropriate string. It can be a random number or some type of user identifier (preferably hashed). |
| audio | [bytes](#bytes) |  | Optional. The input audio content to be recognized. |
| end_of_stream | [bool](#bool) |  | If `true`, the recognizer will not return any further hypotheses about this piece of the audio. May only be populated for `event_type` = `RECOGNITION_EVENT_TRANSCRIPT`. |
| initial_intent_display_name | [string](#string) |  | Optional. Intent display name to trigger in NLU system in the beginning of the conversation. |






<a name="ondewo.csi.S2sStreamResponse"></a>

### S2sStreamResponse
The top-level message returned from the
`S2sStream` method.

A response message is returned for each utterance of the input stream. It contains the full response from NLU system
in `detect_intent_response` or the full T2S response in `synthetize_response`.
Multiple response messages can be returned in order:

1.  The first response message for an input utterance contains response from NLU system `detect_intent_response`
    with detected intent and N fulfillment messages (N >= 0).

2.  The next N response messages contain for each fulfillment message one of the following:
     a. T2S response `synthetize_response` with synthetized audio
     b. SIP trigger message `sip_trigger` with SIP trigger extracted from the fulfillment message


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| detect_intent_response | [ondewo.nlu.DetectIntentResponse](#ondewo.nlu.DetectIntentResponse) |  | full NLU response |
| synthetize_response | [ondewo.t2s.SynthesizeResponse](#ondewo.t2s.SynthesizeResponse) |  | full T2S response |
| sip_trigger | [SipTrigger](#ondewo.csi.SipTrigger) |  | SIP trigger message |






<a name="ondewo.csi.SipTrigger"></a>

### SipTrigger
SIP trigger message


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [SipTrigger.SipTriggerType](#ondewo.csi.SipTrigger.SipTriggerType) |  |  |
| content | [google.protobuf.Struct](#google.protobuf.Struct) |  | extra parameters for the trigger |





 <!-- end messages -->


<a name="ondewo.csi.SipTrigger.SipTriggerType"></a>

### SipTrigger.SipTriggerType
type of the SIP trigger

| Name | Number | Description |
| ---- | ------ | ----------- |
| UNSPECIFIED | 0 | should never be used |
| HANGUP | 1 | hard hangup |
| HUMAN_HANDOVER | 2 | handover to human |
| SEND_NOW | 3 | send now |
| PAUSE | 4 | pause |


 <!-- end enums -->

 <!-- end HasExtensions -->


<a name="ondewo.csi.Conversations"></a>

### Conversations
endpoints of csi service

| Method Name | Request Type | Response Type | Description |
| ----------- | ------------ | ------------- | ------------|
| CreateS2sPipeline | [S2sPipeline](#ondewo.csi.S2sPipeline) | [.google.protobuf.Empty](#google.protobuf.Empty) | Create the S2S pipeline specified in the request message. The pipeline with the specified ID must not exist.

Examples:

``` grpcurl -plaintext -d '{ "id": "pizza", "s2t_pipeline_id": "default_german", "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49", "nlu_language_code": "de", "t2s_pipeline_id": "default_german" }' localhost:50051 ondewo.csi.Conversations.CreateS2sPipeline ```

``` {} ``` |
| GetS2sPipeline | [S2sPipelineId](#ondewo.csi.S2sPipelineId) | [S2sPipeline](#ondewo.csi.S2sPipeline) | Retrieve the S2S pipeline with the ID specified in the request message.

Examples:

``` grpcurl -plaintext -d '{"id": "pizza"}' localhost:50051 ondewo.csi.Conversations.GetS2sPipeline ```

``` { "id": "pizza", "s2t_pipeline_id": "default_german", "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49", "nlu_language_code": "de", "t2s_pipeline_id": "default_german" }

``` |
| UpdateS2sPipeline | [S2sPipeline](#ondewo.csi.S2sPipeline) | [.google.protobuf.Empty](#google.protobuf.Empty) | Update the S2S pipeline specified in the request message. The pipeline must exist.

Examples:

``` grpcurl -plaintext -d '{ "id": "pizza", "s2t_pipeline_id": "default_german", "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49", "nlu_language_code": "en", "t2s_pipeline_id": "default_german" }' localhost:50051 ondewo.csi.Conversations.UpdateS2sPipeline ```

``` {} ``` |
| DeleteS2sPipeline | [S2sPipelineId](#ondewo.csi.S2sPipelineId) | [.google.protobuf.Empty](#google.protobuf.Empty) | Delete the S2S pipeline with the ID specified in the request message. The pipeline must exist.

Examples:

``` grpcurl -plaintext -d '{"id": "pizza"}' localhost:50051 ondewo.csi.Conversations.DeleteS2sPipeline ```

``` {} ``` |
| ListS2sPipelines | [ListS2sPipelinesRequest](#ondewo.csi.ListS2sPipelinesRequest) | [ListS2sPipelinesResponse](#ondewo.csi.ListS2sPipelinesResponse) | List all S2S pipelines of the server.

Examples:

``` grpcurl -plaintext localhost:50051 ondewo.csi.Conversations.ListS2sPipelines ```

``` { "pipelines": [ { "id": "pizza", "s2t_pipeline_id": "default_german", "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49", "nlu_language_code": "de", "t2s_pipeline_id": "default_german" } ] } ``` |
| S2sStream | [S2sStreamRequest](#ondewo.csi.S2sStreamRequest) stream | [S2sStreamResponse](#ondewo.csi.S2sStreamResponse) stream | Processes a natural language query in audio format in a streaming fashion and returns structured, actionable data as a result. |
| CheckUpstreamHealth | [.google.protobuf.Empty](#google.protobuf.Empty) | [CheckUpstreamHealthResponse](#ondewo.csi.CheckUpstreamHealthResponse) | Check the health of S2T, NLU and T2S servers

Examples:

``` grpcurl -plaintext localhost:50051 ondewo.csi.Conversations.CheckUpstreamHealth ```

All upstreams healthy: ``` {} ```

All upstreams unhealthy: ``` { "s2t_status": { "code": 14, "message": "failed to connect to all addresses" }, "nlu_status": { "code": 14, "message": "failed to connect to all addresses" }, "t2s_status": { "code": 14, "message": "failed to connect to all addresses" } } ``` |

 <!-- end services -->



## Scalar Value Types

| .proto Type | Notes | C++ | Java | Python | Go | C# | PHP | Ruby |
| ----------- | ----- | --- | ---- | ------ | -- | -- | --- | ---- |
| <a name="double" /> double |  | double | double | float | float64 | double | float | Float |
| <a name="float" /> float |  | float | float | float | float32 | float | float | Float |
| <a name="int32" /> int32 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint32 instead. | int32 | int | int | int32 | int | integer | Bignum or Fixnum (as required) |
| <a name="int64" /> int64 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint64 instead. | int64 | long | int/long | int64 | long | integer/string | Bignum |
| <a name="uint32" /> uint32 | Uses variable-length encoding. | uint32 | int | int/long | uint32 | uint | integer | Bignum or Fixnum (as required) |
| <a name="uint64" /> uint64 | Uses variable-length encoding. | uint64 | long | int/long | uint64 | ulong | integer/string | Bignum or Fixnum (as required) |
| <a name="sint32" /> sint32 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int32s. | int32 | int | int | int32 | int | integer | Bignum or Fixnum (as required) |
| <a name="sint64" /> sint64 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int64s. | int64 | long | int/long | int64 | long | integer/string | Bignum |
| <a name="fixed32" /> fixed32 | Always four bytes. More efficient than uint32 if values are often greater than 2^28. | uint32 | int | int | uint32 | uint | integer | Bignum or Fixnum (as required) |
| <a name="fixed64" /> fixed64 | Always eight bytes. More efficient than uint64 if values are often greater than 2^56. | uint64 | long | int/long | uint64 | ulong | integer/string | Bignum |
| <a name="sfixed32" /> sfixed32 | Always four bytes. | int32 | int | int | int32 | int | integer | Bignum or Fixnum (as required) |
| <a name="sfixed64" /> sfixed64 | Always eight bytes. | int64 | long | int/long | int64 | long | integer/string | Bignum |
| <a name="bool" /> bool |  | bool | boolean | boolean | bool | bool | boolean | TrueClass/FalseClass |
| <a name="string" /> string | A string must always contain UTF-8 encoded or 7-bit ASCII text. | string | String | str/unicode | string | string | string | String (UTF-8) |
| <a name="bytes" /> bytes | May contain any arbitrary sequence of bytes. | string | ByteString | str | []byte | ByteString | string | String (ASCII-8BIT) |

// Copyright 2021 ONDEWO GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

syntax = "proto3";

package ondewo.csi;
import "google/protobuf/empty.proto";
import "google/rpc/status.proto";
import "google/protobuf/struct.proto";
import "ondewo/nlu/session.proto";
import "ondewo/t2s/text-to-speech.proto";

// endpoints of csi service
service Conversations {
    /*
      Create the S2S pipeline specified in the request message. The pipeline with the specified ID must not exist.

      Examples:

      ```
      grpcurl -plaintext -d '{
        "id": "pizza",
        "s2t_pipeline_id": "default_german",
        "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49",
        "nlu_language_code": "de",
        "t2s_pipeline_id": "default_german"
      }' localhost:50051 ondewo.csi.Conversations.CreateS2sPipeline
      ```

      ```
      {}
      ```
     */
    rpc CreateS2sPipeline (S2sPipeline) returns (google.protobuf.Empty) {
    };
    /*
      Retrieve the S2S pipeline with the ID specified in the request message.

      Examples:

      ```
      grpcurl -plaintext -d '{"id": "pizza"}' localhost:50051 ondewo.csi.Conversations.GetS2sPipeline
      ```

      ```
      {
        "id": "pizza",
        "s2t_pipeline_id": "default_german",
        "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49",
        "nlu_language_code": "de",
        "t2s_pipeline_id": "default_german"
      }

      ```
     */
    rpc GetS2sPipeline (S2sPipelineId) returns (S2sPipeline) {
    };
    /*
      Update the S2S pipeline specified in the request message. The pipeline must exist.

      Examples:

      ```
      grpcurl -plaintext -d '{
        "id": "pizza",
        "s2t_pipeline_id": "default_german",
        "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49",
        "nlu_language_code": "en",
        "t2s_pipeline_id": "default_german"
      }' localhost:50051 ondewo.csi.Conversations.UpdateS2sPipeline
      ```

      ```
      {}
      ```
     */
    rpc UpdateS2sPipeline (S2sPipeline) returns (google.protobuf.Empty) {
    };
    /*
      Delete the S2S pipeline with the ID specified in the request message. The pipeline must exist.

      Examples:

      ```
      grpcurl -plaintext -d '{"id": "pizza"}' localhost:50051 ondewo.csi.Conversations.DeleteS2sPipeline
      ```

      ```
      {}
      ```
     */
    rpc DeleteS2sPipeline (S2sPipelineId) returns (google.protobuf.Empty) {
    };
    /*
      List all S2S pipelines of the server.

      Examples:

      ```
      grpcurl -plaintext localhost:50051 ondewo.csi.Conversations.ListS2sPipelines
      ```

      ```
      {
        "pipelines": [
          {
            "id": "pizza",
            "s2t_pipeline_id": "default_german",
            "nlu_project_id": "1f3425d2-41fd-4970-87e6-88e8e121bb49",
            "nlu_language_code": "de",
            "t2s_pipeline_id": "default_german"
          }
        ]
      }
      ```
     */
    rpc ListS2sPipelines (ListS2sPipelinesRequest) returns (ListS2sPipelinesResponse) {
    };
    /*
      Processes a natural language query in audio format in a streaming fashion
      and returns structured, actionable data as a result.
     */
    rpc S2sStream (stream S2sStreamRequest) returns (stream S2sStreamResponse) {
    };
    /*
      Check the health of S2T, NLU and T2S servers

      Examples:

      ```
      grpcurl -plaintext localhost:50051 ondewo.csi.Conversations.CheckUpstreamHealth
      ```

      All upstreams healthy:
      ```
      {}
      ```

      All upstreams unhealthy:
      ```
      {
        "s2t_status": {
          "code": 14,
          "message": "failed to connect to all addresses"
        },
        "nlu_status": {
          "code": 14,
          "message": "failed to connect to all addresses"
        },
        "t2s_status": {
          "code": 14,
          "message": "failed to connect to all addresses"
        }
      }
      ```
     */
    rpc CheckUpstreamHealth(google.protobuf.Empty) returns (CheckUpstreamHealthResponse) {
    };

}

// The top-level message sent by client to `CreateS2sPipeline` and `UpdateS2sPipeline` endpoints and received from
// `GetS2sPipeline` endpoint.
message S2sPipeline {
    // Required. CSI pipeline identifier consisting of S2T, NLU and T2S configuration. ID can be any non-empty string.
    string id = 1;
    // Required. S2T pipeline ID, e.g. "german_general"
    string s2t_pipeline_id = 2;
    // Required. NLU project ID, usually a hash, e.g. "ae33586b-afda-494a-aa73-1af0589cfc56".
    string nlu_project_id = 3;
    // Required. Language code present in the corresponding NLU project, e.g. "de".
    string nlu_language_code = 4;
    // Required. T2S pipeline ID, e.g. "kerstin".
    string t2s_pipeline_id = 5;
}

// The top-level message sent by client to `GetS2sPipeline` and `DeleteS2sPipeline` endpoints.
message S2sPipelineId {
    // Required. CSI pipeline identifier.
    string id = 1;
}

// The top-level message sent by client to `ListS2sPipelines` endpoint. Currently without arguments.
message ListS2sPipelinesRequest {
    // TODO: add filtering options
}

// The top-level message received from `ListS2sPipelines` endpoint.
message ListS2sPipelinesResponse {
    // Collection of S2S pipelines of the server.
    repeated S2sPipeline pipelines = 1;
}

// The top-level message sent by the client to the
// `S2sStream` method.
//
// Multiple request messages should be sent in order:
//
// 1.  The first message must contain `pipeline_id` and can contain `session_id` or `initial_intent_display_name`.
//     The message must not contain `audio` nor `end_of_stream`.
//
// 2.  All subsequent messages must contain `audio`. If `end_of_stream` is `true`, the stream is closed.
message S2sStreamRequest {
    // Optional. The CSI pipeline ID specified in the initial request.
    string pipeline_id = 1;
    // Optional. The session or call ID specified in the initial request. It’s up to the API caller to choose
    // an appropriate string. It can be a random number or some type of user identifier (preferably hashed).
    string session_id = 2;
    // Optional. The input audio content to be recognized.
    bytes audio = 3;
    // If `true`, the recognizer will not return
    // any further hypotheses about this piece of the audio. May only be populated
    // for `event_type` = `RECOGNITION_EVENT_TRANSCRIPT`.
    bool end_of_stream = 4;
    // Optional. Intent display name to trigger in NLU system in the beginning of the conversation.
    string initial_intent_display_name = 5;
}

// The top-level message returned from the
// `S2sStream` method.
//
// A response message is returned for each utterance of the input stream. It contains the full response from NLU system
// in `detect_intent_response` or the full T2S response in `synthetize_response`.
// Multiple response messages can be returned in order:
//
// 1.  The first response message for an input utterance contains response from NLU system `detect_intent_response`
//     with detected intent and N fulfillment messages (N >= 0).
//
// 2.  The next N response messages contain for each fulfillment message one of the following:
//      a. T2S response `synthetize_response` with synthetized audio
//      b. SIP trigger message `sip_trigger` with SIP trigger extracted from the fulfillment message
message S2sStreamResponse {
    oneof response {
        // full NLU response
        ondewo.nlu.DetectIntentResponse detect_intent_response = 1;
        // full T2S response
        ondewo.t2s.SynthesizeResponse synthetize_response = 2;
        // SIP trigger message
        SipTrigger sip_trigger = 3;
    }
}

// SIP trigger message
message SipTrigger {
    // type of the SIP trigger
    enum SipTriggerType {
        // should never be used
        UNSPECIFIED = 0;
        // hard hangup
        HANGUP = 1;
        // handover to human
        HUMAN_HANDOVER = 2;
        // send now
        SEND_NOW = 3;
        // pause
        PAUSE = 4;
    }
    SipTriggerType type = 1;

    // extra parameters for the trigger
    google.protobuf.Struct content = 2;
}

message CheckUpstreamHealthResponse {
    google.rpc.Status s2t_status = 1;
    google.rpc.Status nlu_status = 2;
    google.rpc.Status t2s_status = 3;
}
defmodule ExBackend.EbuIngestTest do
  use ExBackendWeb.ConnCase

  alias ExBackend.Workflows
  alias ExBackend.WorkflowStep

  require Logger

  describe "ebu_ingest_workflow" do
    test "test ebu ingest workflow" do
      filename = "/data/input_filename.mp4"

      steps = ExBackend.Workflow.Definition.EbuIngest.get_definition("identifier", filename)

      workflow_params = %{
        reference: filename,
        flow: steps
      }

      {:ok, workflow} = Workflows.create_workflow(workflow_params)
      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 1)
      ExBackend.HelpersTest.check(workflow.id, "upload_file", 1)

      params =
        ExBackend.HelpersTest.complete_jobs(workflow.id, "upload_file")
        |> List.first()
        |> Map.get(:params)

      uploaded_file = "/data/" <> (workflow.id |> Integer.to_string()) <> "/input_filename.mp4"

      wav_extracted_file =
        "/data/" <> (workflow.id |> Integer.to_string()) <> "/2_input_filename.mp4.wav"

      audio_dash_file =
        "/data/" <> (workflow.id |> Integer.to_string()) <> "/3_input_filename.mp4.mp4"

      video_dash_file =
        "/data/" <> (workflow.id |> Integer.to_string()) <> "/4_input_filename.mp4-standard5.mp4"

      webvtt_file =
        "/data/" <> (workflow.id |> Integer.to_string()) <> "/2_input_filename.mp4.wav.vtt"

      assert %{
               "destination" => %{
                 "path" => uploaded_file
               },
               "source" => %{
                 "agent" => "identifier",
                 "path" => "/data/input_filename.mp4"
               }
             } == params

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 2)
      ExBackend.HelpersTest.check(workflow.id, "copy", 1)

      params =
        ExBackend.HelpersTest.complete_jobs(workflow.id, "copy")
        |> List.first()
        |> Map.get(:params)

      assert %{
               "action" => "copy",
               "parameters" => [
                 %{"default" => "/archive/#workflow_id",
                 "enable" => false,
                 "id" => "output_directory",
                 "type" => "string",
                 "value" => "/archive/" <> (workflow.id |> Integer.to_string())
                 }
               ],
               "requirements" => %{
                 "paths" => [
                   uploaded_file
                 ]
               },
               "source" => %{
                 "paths" => [
                   uploaded_file
                 ]
               }
             } == params

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 3)
      ExBackend.HelpersTest.check(workflow.id, "audio_extraction", 1)

      params =
        ExBackend.HelpersTest.complete_jobs(workflow.id, "audio_extraction")
        |> List.first()
        |> Map.get(:params)

      assert %{
               "inputs" => [
                 %{
                   "options" => %{},
                   "path" => [uploaded_file]
                 }
               ],
               "outputs" => [
                 %{
                   "options" => [
                     %{
                       "default" => "pcm_s16le",
                       "enable" => false,
                       "id" => "output_codec_audio",
                       "type" => "string",
                       "value" => "pcm_s16le"
                     },
                     %{
                       "default" => 16000,
                       "enable" => false,
                       "id" => "audio_sampling_rate",
                       "type" => "integer",
                       "value" => 16000
                     },
                     %{
                       "default" => 1,
                       "enable" => false,
                       "id" => "audio_channels",
                       "type" => "integer",
                       "value" => 1
                     },
                     %{
                       "default" => true,
                       "enable" => false,
                       "id" => "disable_video",
                       "type" => "boolean",
                       "value" => true
                     },
                     %{
                       "default" => true,
                       "enable" => false,
                       "id" => "disable_data",
                       "type" => "boolean",
                       "value" => true
                     }
                   ],
                   "path" => wav_extracted_file
                 }
               ],
               "requirements" => %{
                 "paths" => [uploaded_file]
               }
             } == params

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 4)
      ExBackend.HelpersTest.check(workflow.id, "audio_extraction", 2)

      params =
        ExBackend.HelpersTest.complete_jobs(workflow.id, "audio_extraction")
        |> List.first()
        |> Map.get(:params)

      assert %{
               "inputs" => [
                 %{
                   "options" => %{},
                   "path" => [uploaded_file]
                 }
               ],
               "outputs" => [
                 %{
                   "options" => [
                     %{
                       "default" => "aac",
                       "enable" => false,
                       "id" => "output_codec_audio",
                       "type" => "string",
                       "value" => "aac"
                     },
                     %{
                       "default" => true,
                       "enable" => false,
                       "id" => "disable_video",
                       "type" => "boolean",
                       "value" => true
                     },
                     %{
                       "default" => true,
                       "enable" => false,
                       "id" => "disable_data",
                       "type" => "boolean",
                       "value" => true
                     }
                   ],
                   "path" => audio_dash_file
                 }
               ],
               "requirements" => %{
                 "paths" => [
                   uploaded_file
                 ]
               }
             } == params

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 5)
      ExBackend.HelpersTest.check(workflow.id, "audio_extraction", 3)

      params =
        ExBackend.HelpersTest.complete_jobs(workflow.id, "audio_extraction")
        |> List.first()
        |> Map.get(:params)

      assert %{
               "inputs" => [
                 %{
                   "path" => [uploaded_file],
                   "options" => %{}
                 }
               ],
               "outputs" => [
                 %{
                   "path" => video_dash_file,
                   "options" => [
                     %{
                       "default" => "libx264",
                       "enable" => false,
                       "id" => "output_codec_video",
                       "type" => "string",
                       "value" => "libx264"
                     },
                     %{
                       "default" => "baseline",
                       "enable" => false,
                       "id" => "profile_video",
                       "type" => "string",
                       "value" => "baseline"
                     },
                     %{
                       "default" => "yuv420p",
                       "enable" => false,
                       "id" => "pixel_format",
                       "type" => "string",
                       "value" => "yuv420p"
                     },
                     %{
                       "default" => "bt709",
                       "enable" => false,
                       "id" => "colorspace",
                       "type" => "string",
                       "value" => "bt709"
                     },
                     %{
                       "default" => "bt709",
                       "enable" => false,
                       "id" => "color_trc",
                       "type" => "string",
                       "value" => "bt709"
                     },
                     %{
                       "default" => "bt709",
                       "enable" => false,
                       "id" => "color_primaries",
                       "type" => "string",
                       "value" => "bt709"
                     },
                     %{
                       "default" => "5M",
                       "enable" => false,
                       "id" => "max_bitrate",
                       "type" => "string",
                       "value" => "5M"
                     },
                     %{
                       "default" => "5M",
                       "enable" => false,
                       "id" => "buffer_size",
                       "type" => "string",
                       "value" => "5M"
                     },
                     %{
                       "default" => "5M",
                       "enable" => false,
                       "id" => "rc_init_occupancy",
                       "type" => "string",
                       "value" => "5M"
                     },
                     %{
                       "default" => "slow",
                       "enable" => false,
                       "id" => "preset",
                       "type" => "string",
                       "value" => "slow"
                     },
                     %{
                       "default" => "keyint=50:min-keyint=50:no-scenecut",
                       "enable" => false,
                       "id" => "x264-params",
                       "type" => "string",
                       "value" => "keyint=50:min-keyint=50:no-scenecut"
                     },
                     %{
                       "default" => "2:2",
                       "enable" => false,
                       "id" => "deblock",
                       "type" => "string",
                       "value" => "2:2"
                     },
                     %{
                       "default" => false,
                       "enable" => false,
                       "id" => "write_timecode",
                       "type" => "boolean",
                       "value" => false
                     },
                     %{
                       "default" => true,
                       "enable" => false,
                       "id" => "disable_audio",
                       "type" => "boolean",
                       "value" => true
                     },
                     %{
                       "default" => true,
                       "enable" => false,
                       "id" => "disable_data",
                       "type" => "boolean",
                       "value" => true
                     }
                   ]
                 }
               ],
               "requirements" => %{
                 "paths" => [
                   uploaded_file
                 ]
               }
             } == params

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)
      ExBackend.HelpersTest.check(workflow.id, 6)
      ExBackend.HelpersTest.check(workflow.id, "speech_to_text", 1)

      params =
        ExBackend.HelpersTest.complete_jobs(workflow.id, "speech_to_text")
        |> List.first()
        |> Map.get(:params)

      assert %{
               "inputs" => [
                 %{
                   "path" => wav_extracted_file
                 }
               ],
               "outputs" => [
                 %{
                   "path" => webvtt_file
                 }
               ],
               "requirements" => %{
                 "paths" => [
                   wav_extracted_file
                 ]
               },
               "format" => "simple",
               "language" => "en-US",
               "mode" => "conversation"
             } == params

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)

      ExBackend.HelpersTest.check(workflow.id, 7)
      ExBackend.HelpersTest.check(workflow.id, "set_language", 1)

      ExBackend.HelpersTest.complete_jobs(workflow.id, "set_language")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)

      ExBackend.HelpersTest.check(workflow.id, 8)
      ExBackend.HelpersTest.check(workflow.id, "generate_dash", 1)

      ExBackend.HelpersTest.complete_jobs(workflow.id, "generate_dash")

      {:ok, "started"} = WorkflowStep.start_next_step(workflow)

      ExBackend.HelpersTest.check(workflow.id, 9)
      ExBackend.HelpersTest.check(workflow.id, "copy", 2)

      ExBackend.HelpersTest.complete_jobs(workflow.id, "copy")

      {:ok, "completed"} = WorkflowStep.start_next_step(workflow)
    end
  end
end

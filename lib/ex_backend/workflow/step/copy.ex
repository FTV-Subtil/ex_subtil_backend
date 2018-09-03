defmodule ExBackend.Workflow.Step.Copy do
  alias ExBackend.Jobs
  alias ExBackend.Amqp.JobFileSystemEmitter
  alias ExBackend.Workflow.Step.Requirements

  @action_name "copy"

  def launch(workflow, step) do
    case get_source_files(workflow.jobs) do
      [] ->
        Jobs.create_skipped_job(workflow, @action_name)

      paths ->
        requirements = Requirements.add_required_paths(paths)

        job_params = %{
          name: @action_name,
          workflow_id: workflow.id,
          params: %{
            action: "copy",
            requirements: requirements,
            source: %{
              paths: paths
            },
            parameters: Map.get(step, "parameters")
          }
        }

        {:ok, job} = Jobs.create_job(job_params)

        params = %{
          job_id: job.id,
          parameters: job.params
        }

        JobFileSystemEmitter.publish_json(params)
        {:ok, "started"}
    end
  end

  defp get_source_files(jobs) do
    ExBackend.Workflow.Step.UploadFile.get_jobs_destination_paths(jobs)
  end

  defp get_paths_directory(_paths, directories \\ [])
  defp get_paths_directory([], directories), do: directories

  defp get_paths_directory(paths, directories) do
    dir =
      List.first(paths)
      |> Path.dirname()

    List.insert_at(directories, -1, dir)
  end

  @doc """
  Returns the list of destination paths of this workflow step
  """
  def get_jobs_destination_paths(_jobs, result \\ [])
  def get_jobs_destination_paths([], result), do: result

  def get_jobs_destination_paths([job | jobs], result) do
    result =
      case job.name do
        @action_name ->
          job.params
          |> Map.get("destination", %{})
          |> Map.get("paths")
          |> case do
            nil -> result
            paths -> Enum.concat(paths, result)
          end

        _ ->
          result
      end

    get_jobs_destination_paths(jobs, result)
  end
end

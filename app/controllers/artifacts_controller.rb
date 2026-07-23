class ArtifactsController < ApplicationController
  before_action :set_project
  before_action :set_artifact, only: [ :show, :edit, :update, :destroy, :fetch_content, :add_tag, :remove_tag ]

  def show
    @highlights = @artifact.highlights.order(:created_at)
    @outgoing_links = @artifact.outgoing_links.includes(:target_artifact)
    @incoming_links = @artifact.incoming_links.includes(:source_artifact)
    @related_artifacts = find_related(@artifact, @project.artifacts)
  end

  def edit
  end

  def new
    @artifact = @project.artifacts.new
    @artifact_type = params[:type] || "note"
  end

  def create
    @artifact = @project.artifacts.new(artifact_params)

    if @artifact.save
      # Enqueue fetch job for links
      if @artifact.artifact_type == "raw_link" && @artifact.source_url.present?
        WebFetchJob.perform_later(@artifact.id)
      end

      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend("artifact-list", partial: "artifacts/artifact_item", locals: { artifact: @artifact, project: @project }),
            turbo_stream.replace("artifact-form-container", partial: "artifacts/empty_form")
          ]
        }
        format.html { redirect_to project_artifact_path(@project, @artifact) }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @artifact.update(artifact_params)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("artifact_#{@artifact.id}", partial: "artifacts/artifact_item", locals: { artifact: @artifact, project: @project })
        }
        format.html { redirect_to project_artifact_path(@project, @artifact) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Clean up image file if present
    if @artifact.local_asset_path.present? && File.exist?(@artifact.local_asset_path.to_s)
      File.delete(@artifact.local_asset_path)
    end
    @artifact.destroy
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.remove("artifact_#{@artifact.id}"),
          turbo_stream.replace("artifact-reader", partial: "artifacts/empty_reader")
        ]
      }
      format.html { redirect_to @project }
    end
  end

  def fetch_content
    WebFetchJob.perform_later(@artifact.id)
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("artifact_#{@artifact.id}_status", partial: "artifacts/fetch_status", locals: { artifact: @artifact, fetching: true })
      }
      format.html { redirect_to project_artifact_path(@project, @artifact), notice: "Fetching content..." }
    end
  end

  def add_tag
    tag_name = params[:tag_name].to_s.strip.downcase
    if tag_name.present? && tag_name.length <= 50
      @artifact.add_tag(tag_name)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("artifact_#{@artifact.id}_tags", partial: "artifacts/tags", locals: { artifact: @artifact, project: @project })
        }
        format.html { redirect_to project_artifact_path(@project, @artifact) }
      end
    else
      head :unprocessable_entity
    end
  end

  def remove_tag
    tag_name = params[:tag_name].to_s.strip.downcase
    @artifact.remove_tag(tag_name)
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("artifact_#{@artifact.id}_tags", partial: "artifacts/tags", locals: { artifact: @artifact, project: @project })
      }
      format.html { redirect_to project_artifact_path(@project, @artifact) }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_artifact
    @artifact = @project.artifacts.find(params[:id])
  end

  def artifact_params
    params.require(:artifact).permit(:title, :artifact_type, :content, :source_url, :attribution, :local_asset_path)
  end

  def find_related(anchor, all_artifacts)
    return [] if anchor.tag_names.empty?
    anchor_tags = anchor.tag_names.to_set
    candidates = all_artifacts.reject { |a| a.id == anchor.id }
    relationships = candidates.filter_map do |candidate|
      candidate_tags = candidate.tag_names.to_set
      shared = anchor_tags & candidate_tags
      next if shared.empty?
      strength = shared.size.to_f / (anchor_tags | candidate_tags).size
      { artifact: candidate, shared_tags: shared.to_a, strength: strength }
    end
    relationships.sort_by { |r| -r[:strength] }.first(10)
  end
end

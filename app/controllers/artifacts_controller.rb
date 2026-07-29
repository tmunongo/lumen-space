class ArtifactsController < ApplicationController
  before_action :set_project
  before_action :set_artifact, only: [ :show, :edit, :update, :destroy, :fetch_content, :add_tag, :remove_tag, :proxy_pdf ]

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
            turbo_stream.update("artifact-form-container", partial: "artifacts/add_form", locals: { project: @project })
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

  def proxy_pdf
    unless @artifact.pdf? && @artifact.source_url.present?
      head :not_found and return
    end

    begin
      response = HTTParty.get(
        @artifact.source_url,
        headers: {
          "User-Agent" => "Mozilla/5.0 (compatible; LumenSpace/1.0)",
          "Accept" => "application/pdf,*/*"
        },
        follow_redirects: true,
        timeout: 30
      )

      unless response.success?
        head :bad_gateway and return
      end

      content_type = response.headers["content-type"] || "application/pdf"
      send_data response.body,
        type: content_type.split(";").first.strip,
        disposition: "inline",
        filename: "document.pdf"
    rescue => e
      Rails.logger.error "proxy_pdf failed for artifact #{@artifact.id}: #{e.message}"
      head :bad_gateway
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

class ArtifactLinksController < ApplicationController
  def create
    @link = ArtifactLink.new(link_params)
    if @link.save
      respond_to do |format|
        format.turbo_stream {
          artifact = @link.source_artifact
          render turbo_stream: turbo_stream.replace("artifact_#{artifact.id}_links", partial: 'artifacts/links', locals: { artifact: artifact, project: artifact.project })
        }
        format.html { redirect_to project_artifact_path(@link.project, @link.source_artifact) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('link-errors', html: "<p class='error'>#{@link.errors.full_messages.join(', ')}</p>") }
        format.html { redirect_back fallback_location: root_path, alert: @link.errors.full_messages.join(', ') }
      end
    end
  end

  def destroy
    @link = ArtifactLink.find(params[:id])
    artifact = @link.source_artifact
    @link.destroy
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("artifact_#{artifact.id}_links", partial: 'artifacts/links', locals: { artifact: artifact, project: artifact.project })
      }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  private

  def link_params
    params.require(:artifact_link).permit(:source_artifact_id, :target_artifact_id, :project_id, :link_type, :note)
  end
end

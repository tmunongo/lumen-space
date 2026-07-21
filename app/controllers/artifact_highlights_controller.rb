class ArtifactHighlightsController < ApplicationController
  before_action :set_project
  before_action :set_artifact

  def create
    @highlight = @artifact.highlights.new(highlight_params)
    if @highlight.save
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("artifact_#{@artifact.id}_content", partial: 'artifacts/content', locals: { artifact: @artifact, project: @project })
        }
        format.json { render json: { id: @highlight.id }, status: :created }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @highlight = @artifact.highlights.find(params[:id])
    @highlight.destroy
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("artifact_#{@artifact.id}_content", partial: 'artifacts/content', locals: { artifact: @artifact, project: @project })
      }
      format.html { redirect_to project_artifact_path(@project, @artifact) }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_artifact
    @artifact = @project.artifacts.find(params[:artifact_id])
  end

  def highlight_params
    params.require(:artifact_highlight).permit(:selected_text, :note, :style)
  end
end

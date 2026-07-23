class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :archive, :unarchive ]

  def index
    @projects = Project.all
    @projects = @projects.active unless @show_archived
    @projects = sort_projects(@projects)
    @project = Project.new
  end

  def show
    @artifacts = @project.artifacts.recent
    @selected_artifact = params[:artifact_id] ? @project.artifacts.find_by(id: params[:artifact_id]) : nil
  end

  def edit
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("project-list", partial: "projects/project_item", locals: { project: @project }),
            turbo_stream.replace("new-project-form", partial: "projects/new_form", locals: { project: Project.new })
          ]
        end
        format.html { redirect_to @project, notice: "Project created." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("new-project-form", partial: "projects/new_form", locals: { project: @project })
        end
        format.html { render :index }
      end
    end
  end

  def update
    if @project.update(project_params)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("project_#{@project.id}", partial: "projects/project_item", locals: { project: @project })
        }
        format.html { redirect_to @project }
      end
    else
      render :edit
    end
  end

  def destroy
    @project.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("project_#{@project.id}") }
      format.html { redirect_to projects_path, notice: "Project deleted." }
    end
  end

  def archive
    @project.archive!
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("project_#{@project.id}", partial: "projects/project_item", locals: { project: @project })
      }
      format.html { redirect_to projects_path }
    end
  end

  def unarchive
    @project.unarchive!
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("project_#{@project.id}", partial: "projects/project_item", locals: { project: @project })
      }
      format.html { redirect_to projects_path }
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name)
  end

  def sort_projects(projects)
    session[:sort_by] = params[:sort_by] if params[:sort_by]
    case (params[:sort_by] || session[:sort_by] || "modified")
    when "name"     then projects.by_name
    when "created"  then projects.by_created
    else                 projects.by_modified
    end
  end
end

class RelationshipsController < ApplicationController
  before_action :set_project

  def index
    @artifacts = @project.artifacts.includes(:artifact_tags).recent
    @selected_artifact = params[:artifact_id] ? @project.artifacts.find_by(id: params[:artifact_id]) : nil

    if @selected_artifact
      all_artifact_tags = @artifacts.map { |a| { id: a.id, tags: a.tag_names.to_set } }
      @related = compute_related(@selected_artifact, all_artifact_tags, @artifacts)
      @network = compute_network(@selected_artifact, all_artifact_tags, @artifacts)
      @bridges = compute_bridges(all_artifact_tags, @artifacts)
      @tag_suggestions = suggest_tags(@selected_artifact, @related)
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def compute_related(anchor, all_tags_map, all_artifacts)
    anchor_tags = anchor.tag_names.to_set
    return [] if anchor_tags.empty?

    all_artifacts.reject { |a| a.id == anchor.id }.filter_map do |candidate|
      entry = all_tags_map.find { |e| e[:id] == candidate.id }
      candidate_tags = entry ? entry[:tags] : Set.new
      shared = anchor_tags & candidate_tags
      next if shared.empty?
      strength = shared.size.to_f / (anchor_tags | candidate_tags).size
      { artifact: candidate, shared_tags: shared.to_a, strength: strength }
    end.sort_by { |r| -r[:strength] }
  end

  def compute_network(start, all_tags_map, all_artifacts)
    visited = Set.new
    queue = [start]
    network = []

    while queue.any?
      current = queue.shift
      next if visited.include?(current.id)
      visited.add(current.id)
      network << current

      related = compute_related(current, all_tags_map, all_artifacts)
      related.each do |r|
        queue << r[:artifact] unless visited.include?(r[:artifact].id)
      end
    end
    network
  end

  def compute_bridges(all_tags_map, all_artifacts)
    cooccurrence = {}
    all_artifacts.each do |artifact|
      tags = artifact.tag_names
      next if tags.size < 2
      tags.combination(2).each do |t1, t2|
        cooccurrence[t1] ||= {}
        cooccurrence[t1][t2] = (cooccurrence[t1][t2] || 0) + 1
        cooccurrence[t2] ||= {}
        cooccurrence[t2][t1] = (cooccurrence[t2][t1] || 0) + 1
      end
    end

    all_artifacts.select do |artifact|
      tags = artifact.tag_names
      next false if tags.size < 2
      pairs = tags.combination(2).to_a
      total = pairs.sum { |t1, t2| (cooccurrence.dig(t1, t2) || 0) }
      avg = total.to_f / pairs.size
      avg < 2.0
    end
  end

  def suggest_tags(anchor, related)
    return Set.new if related.empty?
    current_tags = anchor.tag_names.to_set
    suggestions = {}
    related.each do |r|
      weight = (r[:strength] * 10).round
      r[:artifact].tag_names.each do |tag|
        next if current_tags.include?(tag)
        suggestions[tag] = (suggestions[tag] || 0) + weight
      end
    end
    suggestions.sort_by { |_, v| -v }.first(5).map(&:first).to_set
  end
end

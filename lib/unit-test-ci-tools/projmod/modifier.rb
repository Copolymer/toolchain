require 'xcodeproj'
require 'xcodeproj/constants'

class Modifier
  def initialize(project_path)
    @project = Xcodeproj::Project.open(project_path)
  end

  def show_targets
    @project.targets.each do |target|
      puts "target : #{target.name}, #{target.product_type}"
    end
  end

  def delete_dependencies(target_name, deps)
    target = @project.targets.find_all{ |target| target.name == target_name}.first
    puts "target : #{target.name}"
    target.dependencies.delete_if do |dep|
      include = (deps.include?(dep.display_name))
      if include
        puts "remove dependency : #{dep.display_name}"
      end
      include
    end
    @project.save
  end

  def add_dependencies(target_name, deps)
    target = @project.targets.find_all{ |target| target.name == target_name }.first
    puts "target : #{target}"
    restore_dep_targets = @project.targets.find_all{ |tar| deps.include?(tar.name)}
    restore_dep_targets.each do |restore_dep_target|
      if @project.targets.find_all{ |target| target.name == restore_dep_target}.empty?
        puts "project not contain target : #{restore_dep_target}"
        next
      end
      puts "add dependency target : #{restore_dep_target.to_s}"
      target.add_dependency(restore_dep_target)
    end
    @project.save
  end

  def list_dependencies(target_name)
    target = @project.targets.find_all{ |target| target.name == target_name}.first
    puts "target : #{target}"
    target.dependencies.each do |dep|
      puts "dependency : #{dep.display_name}"
    end

    target.build_phases.each do |build_phase|
      puts "build_phase: #{build_phase.display_name} : #{build_phase.class}"
    end
  end

  def delete_embed_app_extensions_phase(target_name, extensions)
    target = @project.targets.find_all{ |target| target.name == target_name}.first
    puts "target : #{target}"

    ext_build_phase = target.build_phases.find_all do |build_phase|
      (build_phase.class == Xcodeproj::Project::Object::PBXCopyFilesBuildPhase && build_phase.dst_subfolder_spec == Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:plug_ins])
    end.first

    extension_product_names = Array.new
    @project.targets.find_all do |target|
      if extensions.include?(target.name)
        extension_product_names << product_name_with_target(target)
      end
    end

    ext_build_phase.files_references.each do |reference|
      ref_tar = reference.referrers.find_all { |referrer| referrer.class == Xcodeproj::Project::PBXNativeTarget}.first
      next unless ref_tar

      if extension_product_names.include?(ref_tar.name)
        puts "delete embed app-extension : #{reference.path}"
        ext_build_phase.remove_file_reference(reference)
      end
    end

    @project.save
  end

  def add_embed_app_extensions_phase(target_name, extensions)
    target = @project.targets.find_all{ |target| target.name == target_name}.first
    puts "target : #{target}"

    ext_build_phases = target.build_phases.find_all do |build_phase|
      (build_phase.class == Xcodeproj::Project::Object::PBXCopyFilesBuildPhase && build_phase.dst_subfolder_spec == Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:plug_ins])
    end

    if ext_build_phases.empty?
      ext_build_phase = target.new_copy_files_build_phase("Embed App Extensions")
    else
      ext_build_phase = ext_build_phases.first
    end

    ext_build_phase.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:plug_ins]

    # 筛选工程中类型是extension的target
    add_dep_ext_targets = @project.targets.find_all do |tar|
      extensions.include?(tar.name) && tar.product_type.include?("com.apple.product-type.app-extension")
    end

    add_dep_ext_targets.each do |target|
      fileRef = @project.new(Xcodeproj::Project::Object::PBXFileReference)
      product_name = product_name_with_target(target)
      fileRef.set_source_tree('BUILT_PRODUCTS_DIR')
      fileRef.set_path("#{product_name}.appex")
      fileRef.set_explicit_file_type
      ext_build_phase.add_file_reference(fileRef, true)
      puts "add embed app-extension : #{fileRef.path}"
    end

    @project.save
  end

  private
  def product_name_with_target(target)
    product_name = target.build_settings('UnitTest')["PRODUCT_NAME"]
    product_name.gsub!(/\$\(TARGET_NAME.*\)/, target.name)
    product_name
  end

end






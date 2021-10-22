# ! /usr/bin/ruby
# 修改xcode，添加或删除code-check检测target

require 'xcodeproj'
require 'optparse'

# 全局变量
$source_root = ''
$project_name = ''
$user_command = ''
$issue_id = ''
$just_show = true

CODE_CHECK_TARGET_NAME = "CodeCheck"

def true?(obj)
  obj.to_s.downcase == "true"
end

OptionParser.new do |parser|
  parser.on('--srcroot[=SRCROOT]') do |srcroot|
    $source_root = srcroot
  end

  parser.on('--project[=PROJECT]') do |project|
    $project_name = project
  end

  parser.on('--command[=USER_COMMAND]') do |command|
    $user_command = command
  end
  
  parser.on('--issue[=ISSUE_ID]') do |issue|
    $issue_id = issue
  end

  parser.on('--justshow[=JUST_SHOW]') do |justshow|
    $just_show = true?(justshow)
  end
end.parse!

def remove_code_check_target(project)
  project.targets.each do |target|
    target.remove_from_project if target.name == CODE_CHECK_TARGET_NAME
  end
end

def add_code_check_target(project)
  remove_code_check_target(project)
  code_check_target = project.new_aggregate_target(CODE_CHECK_TARGET_NAME)
  code_check_phase = code_check_target.new_shell_script_build_phase('[code-check]')
  if $just_show == true
    code_check_phase.shell_script = 'code-check icheck -r ${SRCROOT} -i ' + $issue_id + ' -s'  
  else
    code_check_phase.shell_script = 'code-check icheck -r ${SRCROOT} -i ' + $issue_id
  end
  
end

path_to_project = "#{$source_root}/#{$project_name}.xcodeproj"
project = Xcodeproj::Project.open(path_to_project)

if $user_command == 'remove'
  remove_code_check_target(project)
elsif $user_command == 'add'
  add_code_check_target(project)
end

project.save

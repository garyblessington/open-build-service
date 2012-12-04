require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class UserTest < ActiveSupport::TestCase

  fixtures :all

  def setup
    @project = projects( :home_Iggy )
    @user = User.find_by_login("Iggy")
  end

  def test_basics
    assert @project
    assert @user

    a = StaticPermission.new :title => 'this-one-should_go_through'
    assert a.valid?
    a.delete
  end

  def test_access
    assert @user.has_local_permission? 'change_project', @project
    assert @user.has_local_permission? 'change_package', packages( :TestPack )

    m = Role.find_by_title("maintainer")
    assert @user.has_local_role?(m, @project )
    assert @user.has_local_role?(m, packages( :TestPack ) )

    b = Role.find_by_title "bugowner"
    assert !@user.has_local_role?(b, @project )
    assert !@user.has_local_role?(m, projects( :kde4 ))

    user = users(:adrian)
    assert !user.has_local_role?(m, @project )
    assert !user.has_local_role?(m, packages( :TestPack ) )
    assert user.has_local_role?(m, projects( :kde4 ))
    assert user.has_local_role?(m, packages( :kdelibs ))

    tom = users( :tom )
    assert !tom.has_local_permission?('change_project', projects( :kde4 ))
    assert !tom.has_local_permission?('change_package', packages( :kdelibs ))
  end

  def test_group
    assert !@user.is_in_group?("notexistant")
    assert !@user.is_in_group?("test_group")
    assert users(:adrian).is_in_group?("test_group")
    assert !users(:adrian).is_in_group?("test_group_b")
    assert !users(:adrian).is_in_group?("notexistant")
  end

  def test_attribute
    obs = attrib_namespaces( :obs )
    assert !@user.can_modify_attribute_definition?(obs)

    assert users( :king ).can_modify_attribute_definition?(obs)
  end

  def test_render_axml
    axml = users( :king ).render_axml
    assert_xml_tag axml, :tag => :globalrole, :content => "Admin"
    axml = users( :tom ).render_axml
    assert_no_xml_tag axml, :tag => :globalrole, :content => "Admin"
  end

  def test_ldap
    assert !@user.local_role_check_with_ldap( roles(:maintainer), @project)
    ldm = Suse::Ldap.enabled?
    lgs = Suse::Ldap.group_support?
    ApplicationSettings::LdapMode.set!(true)
    ApplicationSettings::LdapGroupSupport.set!(true)

    user = users( :tom )
    assert !user.has_local_permission?('change_project', projects( :kde4) )
    assert !user.has_local_permission?('change_package', packages( :kdelibs ))

    ApplicationSettings::LdapMode.set!(ldm)
    ApplicationSettings::LdapGroupSupport.set!(lgs)
  end

  def test_states
    assert_not_nil User.states
  end

  def test_ldap_group_member_of_validation_failure
    gmov = Suse::Ldap.group_member_of_validation?
    ApplicationSettings::LdapGroupMemberOfValidation.set!(true)
    group = groups(:test_group)
    group.ldap_group_member_of_validation = true
    group.save

    user = users(:adrian)
    assert user.accessible_groups(:refresh_cache => true).include?(group) == false

    group.ldap_group_member_of_validation = false
    group.save
    ApplicationSettings::LdapGroupMemberOfValidation.set!(gmov)
  end

  def test_ldap_group_member_of_validation_success
    gmov = Suse::Ldap.group_member_of_validation?
    ApplicationSettings::LdapGroupMemberOfValidation.set!(true)
    group = groups(:test_group)
    group.ldap_group_member_of_validation = true
    group.save

    user = users(:adrian)
    User.expects(:render_grouplist_ldap).with(user.groups.map(&:title), user.login).returns([group.title])
    assert user.accessible_groups(:refresh_cache => true).include?(group) == true

    group.ldap_group_member_of_validation = false
    group.save
    ApplicationSettings::LdapGroupMemberOfValidation.set!(gmov)
  end
end

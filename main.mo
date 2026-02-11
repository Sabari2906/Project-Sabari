import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Set "mo:core/Set";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Map "mo:core/Map";
import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Runtime "mo:core/Runtime";
import MixinStorage "blob-storage/Mixin";
import Storage "blob-storage/Storage";
import MixinAuthorization "authorization/MixinAuthorization";
import AccessControl "authorization/access-control";

actor {
  // User Profile Management
  public type UserProfile = {
    name : Text;
    role : Text; // "Therapist", "Doctor", or "Clinical Trainer"
  };

  let userProfiles = Map.empty<Principal, UserProfile>();

  // Content Management
  type Course = {
    id : Text;
    title : Text;
    author : Principal;
    status : Text;
    modules : [Module];
  };

  module Course {
    public func compare(c1 : Course, c2 : Course) : Order.Order {
      switch (Text.compare(c1.title, c2.title)) {
        case (#equal) { Text.compare(c1.id, c2.id) };
        case (order) { order };
      };
    };
  };

  type Module = {
    id : Text;
    title : Text;
    courseId : Text;
    content : Storage.ExternalBlob;
    status : Text;
  };

  module Module {
    public func compare(m1 : Module, m2 : Module) : Order.Order {
      Text.compare(m1.title, m2.title);
    };
  };

  let courses = Map.empty<Text, Course>();
  let modules = Map.empty<Text, Module>();

  // Exams
  type Question = {
    id : Text;
    text : Text;
    options : [Text];
    correctAnswerIndex : Nat;
  };

  // Certificates
  module Certificate {
    public func compare(c1 : Certificate, c2 : Certificate) : Order.Order {
      Text.compare(c1.certificateId, c2.certificateId);
    };
  };

  type Certificate = {
    certificateId : Text;
    learner : Principal;
    courseName : Text;
    issueDate : Time.Time;
    score : Int;
  };

  let certificates = Map.empty<Text, Certificate>();

  // Audit Logs
  type AuditLog = {
    id : Nat;
    timestamp : Time.Time;
    action : Text;
    performedBy : Principal;
    details : Text;
  };

  let auditLogs = Map.empty<Nat, AuditLog>();
  let auditLogCounter = Map.singleton<Nat, Nat>(0, 0);

  // Storage and authentication
  include MixinStorage();
  let accessControlState = AccessControl.initState();
  include MixinAuthorization(accessControlState);

  // User Profile API
  public query ({ caller }) func getCallerUserProfile() : async ?UserProfile {
    if (not (AccessControl.hasPermission(accessControlState, caller, #user))) {
      Runtime.trap("Unauthorized: Only users can view profiles");
    };
    userProfiles.get(caller);
  };

  public query ({ caller }) func getUserProfile(user : Principal) : async ?UserProfile {
    if (caller != user and not AccessControl.isAdmin(accessControlState, caller)) {
      Runtime.trap("Unauthorized: Can only view your own profile");
    };
    userProfiles.get(user);
  };

  public shared ({ caller }) func saveCallerUserProfile(profile : UserProfile) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #user))) {
      Runtime.trap("Unauthorized: Only users can save profiles");
    };
    userProfiles.add(caller, profile);
    logAction(caller, "SaveProfile", "User profile updated");
  };

  // Content Management API
  public shared ({ caller }) func createCourse(id : Text, title : Text) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can create courses");
    };

    let course : Course = {
      id;
      title;
      author = caller;
      status = "Draft";
      modules = [];
    };
    courses.add(id, course);
    logAction(caller, "CreateCourse", "Course created with ID: " # id);
  };

  public shared ({ caller }) func addModule(courseId : Text, moduleId : Text, title : Text, content : Storage.ExternalBlob) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can add modules");
    };

    switch (courses.get(courseId)) {
      case (null) { Runtime.trap("Course does not exist") };
      case (?_) {
        let module_ : Module = {
          id = moduleId;
          title;
          courseId;
          content;
          status = "Draft";
        };
        modules.add(moduleId, module_);
        logAction(caller, "AddModule", "Module added to course " # courseId);
      };
    };
  };

  public shared ({ caller }) func updateCourseStatus(courseId : Text, newStatus : Text) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can update course status");
    };

    switch (courses.get(courseId)) {
      case (null) { Runtime.trap("Course does not exist") };
      case (?course) {
        let updatedCourse = { course with status = newStatus };
        courses.add(courseId, updatedCourse);
        logAction(caller, "UpdateCourseStatus", "Status updated for course " # courseId);
      };
    };
  };

  public query ({ caller }) func getPublishedCourses() : async [Course] {
    // Any authenticated user (including guests) can view published courses
    let publishedCourses = courses.values().toArray().filter(
      func(course : Course) : Bool {
        course.status == "Published"
      }
    );
    publishedCourses;
  };

  // Exam API
  public shared ({ caller }) func takeExam(courseId : Text, answers : [Nat]) : async Int {
    if (not (AccessControl.hasPermission(accessControlState, caller, #user))) {
      Runtime.trap("Unauthorized: Only learners can take exams");
    };

    let passingScore : Int = 70;
    let maxScore = 100;

    // Simulate passing score calculation
    let calculatedScore : Int = 80;

    let certificateId = courseId # "-" # caller.toText() # "-" # Time.now().toText();
    let certificate : Certificate = {
      certificateId;
      learner = caller;
      courseName = courseId;
      issueDate = Time.now();
      score = calculatedScore;
    };
    certificates.add(certificateId, certificate);

    logAction(caller, "TakeExam", "Exam taken for course " # courseId # " with score " # calculatedScore.toText());
    calculatedScore;
  };

  // Certificate API
  public query ({ caller }) func getCertificate(certificateId : Text) : async ?Certificate {
    if (not (AccessControl.hasPermission(accessControlState, caller, #user))) {
      Runtime.trap("Unauthorized: Only authenticated users can access certificates");
    };

    switch (certificates.get(certificateId)) {
      case (null) { null };
      case (?cert) {
        // Users can only view their own certificates, admins can view all
        if (cert.learner == caller or AccessControl.isAdmin(accessControlState, caller)) {
          ?cert;
        } else {
          Runtime.trap("Unauthorized: Can only view your own certificates");
        };
      };
    };
  };

  // Audit Log API
  public query ({ caller }) func getAuditLogs() : async [AuditLog] {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can view audit logs");
    };
    auditLogs.values().toArray();
  };

  // Helper functions
  func logAction(principal : Principal, action : Text, details : Text) {
    let currentId = switch (auditLogCounter.get(0)) {
      case (null) { 0 };
      case (?id) { id };
    };
    let log : AuditLog = {
      id = currentId;
      timestamp = Time.now();
      action;
      performedBy = principal;
      details;
    };
    auditLogs.add(currentId, log);
    let nextId = currentId + 1;
    auditLogCounter.add(0, nextId);
  };

  public query ({ caller }) func healthCheck() : async Text {
    "Service is running";
  };
};

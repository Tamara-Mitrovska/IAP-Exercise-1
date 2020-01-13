import ballerina/http;
import ballerina/io;
import ballerinax/java.jdbc;

type Person record {|
    string nameWithInitial;
    string fullName;
    string gender;
    int dateOfBirth?;
    string address;
    int nic?;

|};

type Student record{|
    *Person;
    Father father?;
    Mother mother?;

|};

type Father record{
    *Person;
};

type Mother record{
    *Person;
};

// JDBC Client for H2 database.
jdbc:Client testDB = new ({
    url: "jdbc:h2:file:./students/student-data",
    username: "test",
    password: "test"
});

// Function to handle the return value of the `update` remote function.
function handleUpdate(jdbc:UpdateResult|error returned, string message) {
    if (returned is jdbc:UpdateResult) {
        io:println(message + " status: ", returned.updatedRowCount);
    } else {
        io:println(message + " failed: ", <string>returned.detail()?.message);
    }
}
//Insert student information into a table
function insertStudentInfo(string name1, string name2, string gen, string adr) {
    var ret = testDB->update("CREATE TABLE STUDENTS (nameWithInitial VARCHAR(30), fullName VARCHAR(30), gender VARCHAR(30), address VARCHAR(30))");
    handleUpdate(ret, "Create STUDENTS table");
    // function insertInfo(string name1, string name2) {
    ret = testDB->update("INSERT INTO STUDENTS (nameWithInitial, fullName, gender, address) VALUES (?, ?, ?, ?)", name1, name2, gen, adr);
    handleUpdate(ret, "Insert data to STUDENTS table");
        
}


@http:ServiceConfig {
    basePath: "/students"
    }

service studentService on new http:Listener(9090) {


    @http:ResourceConfig {
        methods:["POST"],
        path: "/info"
    }

    resource function studentService(http:Caller caller, http:Request request) {
        var data = request.getFormParams(); 
            if (data is map<string>) {
                io:println(data);
                string name1 = <string>data["nameWithInitial"];
                io:println(name1);
                string name2 = <string>data["fullName"];
                io:println(name2);
                string gen = <string>data["gender"];
                string adr = <string>data["address"];
                Student newStudent = {fullName:name2, nameWithInitial:name1, gender:gen, address:adr};
                io:println(newStudent);
                insertStudentInfo(newStudent.nameWithInitial, newStudent.fullName, newStudent.gender, newStudent.address);

            }
            
        
        // Send a response back to the caller.
        error? result = caller->respond("Ok!");
        if (result is error) {
            io:println("Error in responding: ", result);
        }
    }
}
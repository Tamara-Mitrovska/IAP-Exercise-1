import ballerina/http;
import ballerina/io;
import ballerinax/java.jdbc;

type Person record {|
    string nameWithInitial;
    string fullName;
    string gender;
    string bday;
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
function insertStudentInfo(string name1, string name2, string gen, string adr, string birthday) {
    var ret = testDB->update("CREATE TABLE STUDENTS_INFO (nameWithInitial VARCHAR(30), fullName VARCHAR(30), gender VARCHAR(30), address VARCHAR(30), bday VARCHAR(30))");
    handleUpdate(ret, "Create STUDENTS_INFO table");
    ret = testDB->update("INSERT INTO STUDENTS_INFO (nameWithInitial, fullName, gender, address, bday) VALUES (?, ?, ?, ?, ?)", name1, name2, gen, adr, birthday);
    handleUpdate(ret, "Insert data to STUDENTS_INFO table");
        
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
                io:println("gender",data["gender"]);
                string gen = <string>data["gender"];
                string adr = <string>data["address"];
                string birthday = <string>data["bday"];
                Student newStudent = {fullName:name2, nameWithInitial:name1, gender:gen, address:adr, bday:birthday};
                io:println(newStudent);
                insertStudentInfo(newStudent.nameWithInitial, newStudent.fullName, newStudent.gender, newStudent.address, newStudent.bday);

            }
            
        
        // Send a response back to the caller.
        error? result = caller->respond("Ok!");
        if (result is error) {
            io:println("Error in responding: ", result);
        }
    }
}
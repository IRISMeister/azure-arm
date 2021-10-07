//javac JDBCSample.java 
//java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
// ToDo: parameterize url 
import java.sql.*;

public class JDBCSample {
    public static void main(String args[]) throws Exception {
        String ip="10.0.1.4";
        if (args.length > 0){
            ip=args[0];
        }

        String url = "jdbc:IRIS://"+ip+":51773/MYAPP";
        System.out.println("Connecting to "+url);

        Class.forName("com.intersystems.jdbc.IRISDriver");
        Connection connection = DriverManager.getConnection(url,"_SYSTEM","sys");
        // Replace _SYSTEM and SYS with a username and password on your system

        String createTable = "CREATE TABLE People(ID int, FirstName varchar(255), LastName varchar(255))";
        String insert1 = "INSERT INTO People VALUES (1, 'John', 'Smith')";
        String insert2 = "INSERT INTO People VALUES (2, 'Jane', 'Doe')";
        String query = "SELECT * FROM People";

        Statement statement = connection.createStatement();
        statement.executeUpdate(createTable);
        statement.executeUpdate(insert1);
        statement.executeUpdate(insert2);
        ResultSet resultSet = statement.executeQuery(query);
        System.out.println("Printing out contents of SELECT query: ");
        while (resultSet.next()) {
            System.out.println(resultSet.getString(1) + ", " + resultSet.getString(2) + ", " + resultSet.getString(3));
        }
        resultSet.close();
        statement.close();
        connection.close();
    }
}
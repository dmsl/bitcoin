import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Writer;
import java.net.URL;
import java.net.URLConnection;

public class IPcurlRequest {

	public static void main(String [] args){

		if(args.length != 1){
			System.err.println("Please provide a file with an IP in each row");
			System.exit(1);
		}

		try {
			File input = new File(args[0]);
			BufferedReader in1 = new BufferedReader(new FileReader(input));
			String ip;
			int count = 0;
			while((ip = in1.readLine()) != null) {
				count++;
			}
			String [] ipTable = new String[count];
			in1.close();

			in1=new BufferedReader(new FileReader(input));
			int k = 0;
			while((ip = in1.readLine()) != null) {
				ipTable[k] = ip;
				k++;
			}

			String fileName = "IPs.csv";
			File IPs = new File(fileName);
			if(IPs.exists() == false)
				IPs.createNewFile();
			else {
				IPs.delete();
				IPs.createNewFile();
			}
			Writer fileWriter = new FileWriter(fileName, true);
			PrintWriter printWriter = new PrintWriter(fileWriter);
			String country = null, region = null, city = null;
			String latitude = null, longitude = null;

			for(int i = 0; i < ipTable.length; i++){
				String fields = "?fields=country,regionName,city,lat,lon";
				String req = "http://ip-api.com/line/";
				URL url = new URL(req + ipTable[i] + fields);
				URLConnection con = url.openConnection();
				BufferedReader in = new BufferedReader(new 
									InputStreamReader(con.getInputStream()));
				
				String inputLine;
				int j = 0;
				while ((inputLine = in.readLine()) != null) {
					switch(j){
						case 0:
							country = inputLine;
                            break;
                        case 1:
                            region = inputLine;
                            break;
                        case 2:
                            city = inputLine;
                            break;
                        case 3:
                            latitude = inputLine;
                            break;
                        case 4:
                            longitude = inputLine;
                            j = -1;
                            break;
					}
					j++;
				}
				in.close();

				printWriter.println(ipTable[i] + "," + country + "," + region + 
					"," + city + "," + latitude + "," + longitude);
				if(i%2==0){
					Thread.sleep(800);
				}
			}
			printWriter.close();
		}catch(Exception e){
			e.printStackTrace();
        }
	}
}

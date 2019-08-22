package testing;

import java.net.URL;

import org.openqa.selenium.Platform;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.testng.Assert;
import org.testng.annotations.AfterTest;
import org.testng.annotations.BeforeTest;
import org.testng.annotations.Test;


public class BowserTest {

	private WebDriver driver;	
	public String homePage = System.getProperty("homePage");
	public String titleText = System.getProperty("titleText");
	//public String homePage = "http://virtualiseme.net.au";
	//public String titleText = "Virtualise Me | Virtualisation Down Under";
	
	
  @Test
  public void homePageTest() {
	  	System.out.println("Testing Website: " + homePage);
		driver.get(homePage);  
		String title = driver.getTitle();				 
		Assert.assertTrue(title.contains(titleText)); 	
  }
  @BeforeTest
  public void beforeTest() throws Exception {
	  driver = new RemoteWebDriver(new URL("http://10.0.10.82:4444/wd/hub"), new DesiredCapabilities("chrome", "" , Platform.WINDOWS));
  }

  @AfterTest
  public void afterTest() {
	  System.out.println("closing web page: " + homePage);
	  driver.quit();
  }

}

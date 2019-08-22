package testing;

import java.net.URL;
import java.util.concurrent.TimeUnit;

import org.openqa.selenium.By;
import org.openqa.selenium.Platform;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.testng.Assert;
import org.testng.annotations.AfterTest;
import org.testng.annotations.BeforeTest;
import org.testng.annotations.Test;



public class AccountTest {

	private WebDriver driver;	
	public String homePage = System.getProperty("homePage");
	public String titleText = System.getProperty("titleText");
	//public String homePage = "http://10.200.11.52:8080/spring-nanotrader-web";
	//public String titleText = "Virtualise Me Trader";
	//added
	
	
	
  @Test
  public void homePageTest() {
	  	System.out.println("Testing Website: " + homePage);
		driver.get(homePage);  
		driver.manage().timeouts().implicitlyWait(60, TimeUnit.SECONDS);
		String title = driver.getTitle();				 
		Assert.assertTrue(title.contains(titleText)); 	
		    driver.findElement(By.id("showRegistrationBtn")).click();
		    driver.findElement(By.id("fullname-input")).clear();
		    driver.findElement(By.id("fullname-input")).sendKeys("Chris Slater");
		    driver.findElement(By.id("reg-username-input")).clear();
		    driver.findElement(By.id("reg-username-input")).sendKeys("chris");
		    driver.findElement(By.id("email-input")).clear();
		    driver.findElement(By.id("email-input")).sendKeys("chris@vmware.com");
		    driver.findElement(By.id("openbalance-input")).clear();
		    driver.findElement(By.id("openbalance-input")).sendKeys("20000");
		    driver.findElement(By.id("reg-password-input")).clear();
		    driver.findElement(By.id("reg-password-input")).sendKeys("P@ssw0rd");
		    driver.findElement(By.id("matchpasswd-input")).clear();
		    driver.findElement(By.id("matchpasswd-input")).sendKeys("P@ssw0rd");
		    driver.findElement(By.id("address-input")).clear();
		    driver.findElement(By.id("address-input")).sendKeys("123 Fake St");
		    driver.findElement(By.id("registrationBtn")).click();
		    driver.findElement(By.cssSelector("span.icon-down-arrow")).click();
		    driver.findElement(By.id("logout")).click();
		    driver.findElement(By.id("username-input")).clear();
		    driver.findElement(By.id("username-input")).sendKeys("chris");
		    driver.findElement(By.id("password-input")).clear();
		    driver.findElement(By.id("password-input")).sendKeys("P@ssw0rd");
		    driver.findElement(By.id("loginBtn")).click();
		
		
  }
  @BeforeTest
  public void beforeTest() throws Exception {
	  driver = new RemoteWebDriver(new URL("http://10.0.10.82:4444/wd/hub"), new DesiredCapabilities("chrome", "" , Platform.WINDOWS));
	  driver.manage().window().maximize();
  }

  @AfterTest
  public void afterTest() {
	  System.out.println("closing web page: " + homePage);
	  driver.quit();
  }

}

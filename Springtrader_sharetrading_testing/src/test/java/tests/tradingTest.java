package tests;

import org.testng.annotations.Test;
import org.testng.annotations.BeforeTest;

import java.net.URL;
import java.util.concurrent.TimeUnit;

import org.openqa.selenium.By;
import org.openqa.selenium.Platform;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.testng.Assert;
import org.testng.annotations.AfterTest;

public class tradingTest {
	private WebDriver driver;	
	public String homePage = System.getProperty("homePage");
	public String titleText = System.getProperty("titleText");
	//public String homePage = "http://10.200.11.50:8080/spring-nanotrader-web/";
	//public String titleText = "Virtualise Me Trader";
	
	
  @Test
  public void homePageTest() {
	  	System.out.println("Testing Website: " + homePage);
		driver.get(homePage);  
		driver.manage().timeouts().implicitlyWait(60, TimeUnit.SECONDS);
		String title = driver.getTitle();				 
		Assert.assertTrue(title.contains(titleText)); 	
	    driver.findElement(By.id("username-input")).clear();
	    driver.findElement(By.id("username-input")).sendKeys("chris");
	    driver.findElement(By.id("password-input")).clear();
	    driver.findElement(By.id("password-input")).sendKeys("P@ssw0rd");
	    driver.findElement(By.id("loginBtn")).click();

	    driver.findElement(By.id("nb-portfolio")).click();
	    driver.findElement(By.id("nb-trade")).click();
	    driver.findElement(By.id("nb-trade")).click();
	    driver.findElement(By.id("quote-input")).clear();
	    driver.findElement(By.id("quote-input")).sendKeys("vmw");
	    //driver.findElement(By.cssSelector("strong")).click();
	    driver.findElement(By.id("getQuoteBtn")).click();
	    driver.findElement(By.id("quantity-input")).clear();
	    driver.findElement(By.id("quantity-input")).sendKeys("10");
	    driver.findElement(By.id("buyBtn")).click();
	    //driver.findElement(By.xpath("(//a[contains(text(),'OK')])[2]")).click();
	    driver.findElement(By.linkText("OK")).click();
	    driver.findElement(By.id("nb-portfolio")).click();
		
		
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
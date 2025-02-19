using Microsoft.AspNetCore.Mvc;

namespace DemoApi.Controllers
{
    public class MyModel
    {
        public required string Message { get; set; }
        public required DateTime Date { get; set; }
        public string Details { get; set; }
    }
    
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {

        [HttpGet]
        public ActionResult<string> Get()
        {
            return "Hello World!";
        }

        [HttpPost]
        public ActionResult<string> Post(MyModel model)
        {
            return Ok(model);
        }
        
    }
}
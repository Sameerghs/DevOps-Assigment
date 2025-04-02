import io
import time
from typing import Dict
from PIL import Image
import pytesseract
import kserve
from kserve import Model, ModelServer, InferRequest, InferResponse, InferInput, InferOutput
from kserve.utils.utils import generate_uuid
import base64
from prometheus_client import Counter, Histogram, start_http_server

# Define Prometheus metrics
INFERENCE_REQUESTS_TOTAL = Counter('inference_requests_total', 'Total number of inference requests')
INFERENCE_ERRORS_TOTAL = Counter('inference_requests_errors_total', 'Total number of inference request errors')
INFERENCE_LATENCY = Histogram('inference_latency_seconds', 'Histogram of inference request latencies')

class OCRModel(Model):
    def __init__(self, name: str):
        super().__init__(name)
        self.name = name
        self.ready = True  # Model is ready to serve

    async def predict(self, infer_request: InferRequest, headers: Dict[str, str] = None) -> InferResponse:
        start_time = time.time()  # Start the timer for latency measurement

        # Extract the binary image data from the inference request
        input_tensor = infer_request.inputs[0]
        base64_image_data = input_tensor.data[0]  # Base64 encoded string
        print(base64_image_data)

        try:
            # Decode base64 string to bytes
            image_data = base64.b64decode(base64_image_data)

            # Open the image using PIL
            image = Image.open(io.BytesIO(image_data))

            # Use Tesseract to extract text from the image
            extracted_text = pytesseract.image_to_string(image)

            # Prepare the inference response
            response_id = generate_uuid()
            output = InferOutput(
                name="output-0",
                shape=[1],
                datatype="BYTES",
                data=[extracted_text]  # Base64 encode the output List
            )
            infer_response = InferResponse(
                model_name=self.name,
                infer_outputs=[output],
                response_id=response_id
            )

            # Record inference success
            INFERENCE_REQUESTS_TOTAL.inc()  # Increment total inference requests counter
            INFERENCE_LATENCY.observe(time.time() - start_time)  # Record inference latency
            return infer_response
        
        except Exception as e:
            # Record error if inference fails
            INFERENCE_ERRORS_TOTAL.inc()  # Increment error counter
            print(f"Error during inference: {e}")
            raise e  # Rethrow the error to indicate failure

if __name__ == "__main__":
    # Start the Prometheus HTTP server on port 8000 to expose the metrics
    start_http_server(8000)
    
    # Start the KServe model server
    model = OCRModel("ocr-model")
    ModelServer().start([model])

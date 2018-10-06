#!/usr/bin/env python
import pika
import time
import json
import multiprocessing

NUM_WORKERS = 8

def calculate(val):
    time.sleep(3)
    return val * val


class RMQWorker(object):
    def __init__(self, num):
        self.num = num
        self.connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
        self.channel = self.connection.channel()
        self.channel.queue_declare(queue='task_queue', durable=True)
        self.channel.basic_qos(prefetch_count=1)
        self.channel.basic_consume(self.callback, queue='task_queue')

    def run(self):
        print(f" [{self.num}] Waiting for messages. To exit press CTRL+C")
        self.channel.start_consuming()

    def callback(self, ch, method, properties, body):
        msg = json.loads(body)
        print(f" [{self.num}] Received %r" % msg)
        ch.basic_ack(delivery_tag = method.delivery_tag)

        cmd = msg['command']
        if cmd == 'calculate':
            val = msg['params']['value']
            resp_queue = msg['respond_to']

            print(f" [{self.num}] Calculating value ...")
            ret = calculate(val)

            response = {
                'task_id': msg['task_id'],
                'result': ret
            }

            print(f" [{self.num}] Done! Sending result: {response}")
            ch.basic_publish(exchange="", routing_key=resp_queue, body=json.dumps(response))

def start_worker(num):
    print(f"Starting worker: {num}")
    worker = RMQWorker(num)
    worker.run()

if __name__ == '__main__':
    for num in range(NUM_WORKERS):
        worker = multiprocessing.Process(target=start_worker, args=(num,))
        worker.start()
